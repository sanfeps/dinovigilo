import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/services/analytics_service.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/history/domain/entities/objective_stats.dart';
import 'package:dinovigilo/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:dinovigilo/features/streak/domain/repositories/streak_repository.dart';

class StreakRepositoryImpl implements StreakRepository {
  final StreakLocalDatasource _datasource;
  final AnalyticsService _analytics;

  const StreakRepositoryImpl(this._datasource, this._analytics);

  @override
  Future<Result<StreakStatus>> getStreakStatus() async {
    try {
      final status = await _datasource.getStreakStatus();
      return Result.success(status);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateStreakStatus(StreakStatus status) async {
    try {
      await _datasource.updateStreakStatus(status);
      _analytics.logEvent('streak_status_updated', {
        'currentStreak': status.currentStreak,
        'isActive': status.isActive,
      });
      return Result.success(null);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<DailyCompletion>>> getCompletionsForDate(
    DateTime date,
  ) async {
    try {
      final completions = await _datasource.getCompletionsForDate(date);
      return Result.success(completions);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<DailyCompletion>> toggleCompletion(
    String completionId,
    bool completed,
  ) async {
    try {
      final completion =
          await _datasource.toggleCompletion(completionId, completed);
      _analytics.logEvent('completion_toggled', {
        'id': completionId,
        'completed': completed,
      });
      return Result.success(completion);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> ensureCompletionsForDate(
    DateTime date,
    List<String> objectiveIds,
  ) async {
    try {
      await _datasource.ensureCompletionsForDate(date, objectiveIds);
      return Result.success(null);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> isDayPerfect(DateTime date) async {
    try {
      final isPerfect = await _datasource.isDayPerfect(date);
      return Result.success(isPerfect);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<StreakStatus> watchStreakStatus() {
    return _datasource.watchStreakStatus();
  }

  @override
  Future<Result<Map<DateTime, List<DailyCompletion>>>>
      getCompletionsForDateRange(DateTime start, DateTime end) async {
    try {
      final data = await _datasource.getCompletionsForDateRange(start, end);
      return Result.success(data);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ObjectiveStats>>> getObjectiveCompletionStats() async {
    try {
      final raw = await _datasource.getObjectiveCompletionStats();
      final stats = raw
          .map((r) => ObjectiveStats(
                objectiveId: r.objectiveId,
                totalDays: r.totalDays,
                completedDays: r.completedDays,
              ))
          .toList();
      return Result.success(stats);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<DailyCompletion>> watchCompletionsForDate(DateTime date) {
    return _datasource.watchCompletionsForDate(date);
  }
}
