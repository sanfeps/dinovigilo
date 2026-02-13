import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/providers/egg_providers.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/sprint/presentation/providers/sprint_providers.dart';
import 'package:dinovigilo/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:dinovigilo/features/streak/data/repositories/streak_repository_impl.dart';
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:dinovigilo/features/streak/domain/repositories/streak_repository.dart';
import 'package:dinovigilo/features/streak/domain/usecases/get_daily_completions.dart';
import 'package:dinovigilo/features/streak/domain/usecases/get_streak_status.dart';
import 'package:dinovigilo/features/streak/domain/usecases/process_day_end.dart';
import 'package:dinovigilo/features/streak/domain/usecases/toggle_objective_completion.dart';

part 'streak_providers.g.dart';

@Riverpod(keepAlive: true)
StreakLocalDatasource streakLocalDatasource(StreakLocalDatasourceRef ref) {
  final db = ref.watch(databaseProvider);
  return StreakLocalDatasource(db);
}

@Riverpod(keepAlive: true)
StreakRepository streakRepository(StreakRepositoryRef ref) {
  final datasource = ref.watch(streakLocalDatasourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return StreakRepositoryImpl(datasource, analytics);
}

@riverpod
GetStreakStatusUseCase getStreakStatusUseCase(GetStreakStatusUseCaseRef ref) {
  return GetStreakStatusUseCase(ref.watch(streakRepositoryProvider));
}

@riverpod
GetDailyCompletionsUseCase getDailyCompletionsUseCase(
  GetDailyCompletionsUseCaseRef ref,
) {
  return GetDailyCompletionsUseCase(ref.watch(streakRepositoryProvider));
}

@riverpod
ToggleObjectiveCompletionUseCase toggleObjectiveCompletionUseCase(
  ToggleObjectiveCompletionUseCaseRef ref,
) {
  return ToggleObjectiveCompletionUseCase(ref.watch(streakRepositoryProvider));
}

@riverpod
ProcessDayEndUseCase processDayEndUseCase(ProcessDayEndUseCaseRef ref) {
  return ProcessDayEndUseCase(ref.watch(streakRepositoryProvider));
}

@riverpod
Stream<StreakStatus> streakStatusStream(StreakStatusStreamRef ref) {
  final repository = ref.watch(streakRepositoryProvider);
  return repository.watchStreakStatus();
}

@riverpod
Stream<List<DailyCompletion>> todayCompletionsStream(
  TodayCompletionsStreamRef ref,
) {
  final repository = ref.watch(streakRepositoryProvider);
  final today = DateTime.now();
  return repository.watchCompletionsForDate(today);
}

@riverpod
Future<List<Objective>> todayObjectives(TodayObjectivesRef ref) async {
  // Watch the active sprint stream so this re-runs when sprint changes
  ref.watch(activeSprintStreamProvider);

  final useCase = ref.watch(getObjectivesForDayUseCaseProvider);
  final result = await useCase.execute(DateTime.now());
  return result.when(
    success: (objectives) => objectives,
    failure: (_) => [],
  );
}

@riverpod
Future<void> initializeTodayCompletions(
  InitializeTodayCompletionsRef ref,
) async {
  final objectives = await ref.watch(todayObjectivesProvider.future);
  if (objectives.isEmpty) return;

  final repository = ref.watch(streakRepositoryProvider);
  final objectiveIds = objectives.map((o) => o.id).toList();
  await repository.ensureCompletionsForDate(DateTime.now(), objectiveIds);
}

@riverpod
Future<void> processDayEndOnStartup(
  ProcessDayEndOnStartupRef ref,
) async {
  final streakRepo = ref.watch(streakRepositoryProvider);
  final processDayEnd = ref.watch(processDayEndUseCaseProvider);
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  // Capture status before processing to detect transitions
  final priorResult = await streakRepo.getStreakStatus();
  final priorStatus = priorResult.isSuccess ? priorResult.data : null;

  final streakResult = await processDayEnd.execute(yesterday);
  if (streakResult.isFailure) return;

  final status = streakResult.data;

  // If processDayEnd was a no-op (day already processed), skip egg/notification logic
  final dayWasProcessed = priorStatus == null ||
      priorStatus.lastPerfectDay != status.lastPerfectDay;
  if (!dayWasProcessed) return;

  // --- Egg System Integration ---
  final checkCreation = ref.watch(checkEggCreationUseCaseProvider);
  final checkHatching = ref.watch(checkEggHatchingUseCaseProvider);
  final advanceEggs = ref.watch(advanceEggsUseCaseProvider);
  final pauseEggs = ref.watch(pauseAllEggsUseCaseProvider);
  final resumeEggs = ref.watch(resumeAllEggsUseCaseProvider);
  final notifications = ref.watch(notificationServiceProvider);

  // Detect streak break: was active, now inactive
  final streakJustBroke =
      priorStatus != null && priorStatus.isActive && !status.isActive;

  // Detect recovery completion: was inactive, now active
  final recoveryJustCompleted =
      priorStatus != null && !priorStatus.isActive && status.isActive;

  if (streakJustBroke) {
    await pauseEggs.execute();
    await notifications.showStreakBreakNotification();
  }

  if (recoveryJustCompleted) {
    await resumeEggs.execute();
    await notifications.showRecoveryCompleteNotification();
  }

  // Show recovery progress notification
  if (!status.isActive &&
      status.recoveryDaysNeeded > 0 &&
      !streakJustBroke) {
    await notifications.showRecoveryProgressNotification(
      status.recoveryDaysNeeded,
    );
  }

  // On perfect day when active: advance egg incubation + check creation
  if (status.isActive && status.totalPerfectDays > 0) {
    // Advance all non-paused eggs by 1 day
    await advanceEggs.execute();

    // Check if a new egg was earned
    final eggResult = await checkCreation.execute(status);
    if (eggResult.isSuccess && eggResult.data != null) {
      await notifications.showEggCreatedNotification(status.currentStreak);
    }

    // Check if any eggs are ready to hatch
    final hatchResult = await checkHatching.execute();
    if (hatchResult.isSuccess && hatchResult.data.isNotEmpty) {
      // Store hatched dinosaurs for UI dialog display
      ref.read(recentlyHatchedDinosaursProvider.notifier).state =
          hatchResult.data;
      for (final dinosaur in hatchResult.data) {
        await notifications.showEggHatchedNotification(dinosaur);
      }
    }
  }
}
