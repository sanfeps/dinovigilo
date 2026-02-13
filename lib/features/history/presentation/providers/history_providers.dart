import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/features/history/domain/entities/objective_stats.dart';
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/features/streak/presentation/providers/streak_providers.dart';

part 'history_providers.g.dart';

@riverpod
Future<Map<DateTime, List<DailyCompletion>>> monthCompletions(
  MonthCompletionsRef ref,
  DateTime month,
) async {
  // Re-fetch when today's completions change so the calendar updates live
  ref.watch(todayCompletionsStreamProvider);

  final repository = ref.watch(streakRepositoryProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0); // last day of month
  final result = await repository.getCompletionsForDateRange(start, end);
  return result.when(
    success: (data) => data,
    failure: (_) => {},
  );
}

@riverpod
Future<List<ObjectiveStats>> objectiveStats(ObjectiveStatsRef ref) async {
  final repository = ref.watch(streakRepositoryProvider);
  final result = await repository.getObjectiveCompletionStats();
  return result.when(
    success: (data) => data,
    failure: (_) => [],
  );
}
