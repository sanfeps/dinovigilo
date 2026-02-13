import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/history/domain/entities/objective_stats.dart';
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';

abstract class StreakRepository {
  Future<Result<StreakStatus>> getStreakStatus();
  Future<Result<void>> updateStreakStatus(StreakStatus status);
  Future<Result<List<DailyCompletion>>> getCompletionsForDate(DateTime date);
  Future<Result<DailyCompletion>> toggleCompletion(
    String completionId,
    bool completed,
  );
  Future<Result<void>> ensureCompletionsForDate(
    DateTime date,
    List<String> objectiveIds,
  );
  Future<Result<bool>> isDayPerfect(DateTime date);
  Future<Result<Map<DateTime, List<DailyCompletion>>>> getCompletionsForDateRange(
    DateTime start,
    DateTime end,
  );
  Future<Result<List<ObjectiveStats>>> getObjectiveCompletionStats();
  Stream<StreakStatus> watchStreakStatus();
  Stream<List<DailyCompletion>> watchCompletionsForDate(DateTime date);
}
