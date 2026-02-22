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

// ---------------------------------------------------------------------------
// Yesterday Buffer Feature
// ---------------------------------------------------------------------------

/// Objectives assigned to yesterday's sprint day.
@riverpod
Future<List<Objective>> yesterdayObjectives(YesterdayObjectivesRef ref) async {
  ref.watch(activeSprintStreamProvider);
  final useCase = ref.watch(getObjectivesForDayUseCaseProvider);
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final result = await useCase.execute(yesterday);
  return result.when(
    success: (objectives) => objectives,
    failure: (_) => [],
  );
}

/// Live stream of completions for yesterday.
@riverpod
Stream<List<DailyCompletion>> yesterdayCompletionsStream(
  YesterdayCompletionsStreamRef ref,
) {
  final repository = ref.watch(streakRepositoryProvider);
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return repository.watchCompletionsForDate(yesterday);
}

/// Ensures DailyCompletion rows exist for yesterday (idempotent).
/// Only runs when the buffer is actually available.
@riverpod
Future<void> initializeYesterdayCompletions(
  InitializeYesterdayCompletionsRef ref,
) async {
  final isAvailable = ref.watch(yesterdayBufferAvailableProvider);
  if (!isAvailable) return;

  final objectives = await ref.watch(yesterdayObjectivesProvider.future);
  if (objectives.isEmpty) return;

  final repository = ref.watch(streakRepositoryProvider);
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final objectiveIds = objectives.map((o) => o.id).toList();
  await repository.ensureCompletionsForDate(yesterday, objectiveIds);
}

/// True when the yesterday-buffer grace card should be shown.
@riverpod
bool yesterdayBufferAvailable(YesterdayBufferAvailableRef ref) {
  final streakAsync = ref.watch(streakStatusStreamProvider);
  final objectivesAsync = ref.watch(yesterdayObjectivesProvider);

  final status = streakAsync.valueOrNull;
  final objectives = objectivesAsync.valueOrNull;

  if (status == null || objectives == null) return false;
  return status.isYesterdayBufferAvailable && objectives.isNotEmpty;
}

/// Notifier that performs the streak restoration when the buffer is used.
@riverpod
class StreakBufferRestoreNotifier extends _$StreakBufferRestoreNotifier {
  @override
  void build() {}

  Future<void> restore() async {
    final streakRepo = ref.read(streakRepositoryProvider);
    final statusResult = await streakRepo.getStreakStatus();
    if (statusResult.isFailure) return;

    final status = statusResult.data;
    if (status.preBreakStreak == 0) return; // Guard: already restored

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayOnly = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
    );

    final newStreak = status.preBreakStreak + 1;
    final newLongest =
        newStreak > status.longestStreak ? newStreak : status.longestStreak;

    final restoredStatus = status.copyWith(
      currentStreak: newStreak,
      isActive: true,
      recoveryDaysNeeded: 0,
      preBreakStreak: 0,
      totalPerfectDays: status.totalPerfectDays + 1,
      longestStreak: newLongest,
      lastPerfectDay: yesterdayOnly,
    );

    await streakRepo.updateStreakStatus(restoredStatus);

    // Resume paused eggs and advance by the one perfect day
    final resumeEggs = ref.read(resumeAllEggsUseCaseProvider);
    await resumeEggs.execute();

    final advanceEggs = ref.read(advanceEggsUseCaseProvider);
    await advanceEggs.execute();

    // Check if a new egg was earned
    final checkCreation = ref.read(checkEggCreationUseCaseProvider);
    await checkCreation.execute(restoredStatus);

    // Check if any eggs hatched
    final checkHatching = ref.read(checkEggHatchingUseCaseProvider);
    final hatchResult = await checkHatching.execute();
    if (hatchResult.isSuccess && hatchResult.data.isNotEmpty) {
      ref.read(recentlyHatchedDinosaursProvider.notifier).state =
          hatchResult.data;
    }
  }
}
