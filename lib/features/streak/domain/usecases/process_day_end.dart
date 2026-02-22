import 'package:dinovigilo/core/constants/app_constants.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:dinovigilo/features/streak/domain/repositories/streak_repository.dart';

class ProcessDayEndUseCase {
  final StreakRepository _repository;

  const ProcessDayEndUseCase(this._repository);

  /// Processes the given day's completion data and updates the streak.
  /// Should be called with yesterday's date on app startup.
  /// Idempotent: skips if lastPerfectDay >= the given day.
  Future<Result<StreakStatus>> execute(DateTime day) async {
    final statusResult = await _repository.getStreakStatus();
    if (statusResult.isFailure) return statusResult;

    var status = statusResult.data;
    final dayOnly = DateTime(day.year, day.month, day.day);

    // Skip if already processed
    if (status.lastPerfectDay != null) {
      final lastDate = DateTime(
        status.lastPerfectDay!.year,
        status.lastPerfectDay!.month,
        status.lastPerfectDay!.day,
      );
      if (!lastDate.isBefore(dayOnly)) {
        return Result.success(status);
      }
    }

    // Check if there were any completions for this day
    final completionsResult = await _repository.getCompletionsForDate(day);
    if (completionsResult.isFailure) {
      return Result.failure(completionsResult.error);
    }

    final completions = completionsResult.data;
    if (completions.isEmpty) {
      // No objectives assigned for this day, no streak change
      return Result.success(status);
    }

    final perfectResult = await _repository.isDayPerfect(day);
    if (perfectResult.isFailure) {
      return Result.failure(perfectResult.error);
    }

    final wasPerfect = perfectResult.data;

    if (wasPerfect) {
      final newTotalPerfectDays = status.totalPerfectDays + 1;

      if (status.isActive) {
        // Active streak: increment
        final newStreak = status.currentStreak + 1;
        final newLongest =
            newStreak > status.longestStreak ? newStreak : status.longestStreak;
        status = status.copyWith(
          currentStreak: newStreak,
          totalPerfectDays: newTotalPerfectDays,
          longestStreak: newLongest,
          lastPerfectDay: dayOnly,
        );
      } else {
        // Recovery mode: decrement recovery days
        final newRecovery = status.recoveryDaysNeeded - 1;
        if (newRecovery <= 0) {
          // Recovery complete, reactivate
          status = status.copyWith(
            isActive: true,
            recoveryDaysNeeded: 0,
            preBreakStreak: 0,
            totalPerfectDays: newTotalPerfectDays,
            lastPerfectDay: dayOnly,
          );
        } else {
          status = status.copyWith(
            recoveryDaysNeeded: newRecovery,
            preBreakStreak: 0,
            totalPerfectDays: newTotalPerfectDays,
            lastPerfectDay: dayOnly,
          );
        }
      }
    } else {
      // Not a perfect day
      if (status.isActive && status.currentStreak > 0) {
        // Break the streak - save current streak for yesterday-buffer grace period
        status = status.copyWith(
          isActive: false,
          preBreakStreak: status.currentStreak,
          currentStreak: 0,
          recoveryDaysNeeded: AppConstants.recoveryDaysRequired,
          lastPerfectDay: dayOnly,
        );
      } else if (!status.isActive) {
        // Already in recovery, buffer expired — reset counter
        status = status.copyWith(
          recoveryDaysNeeded: AppConstants.recoveryDaysRequired,
          preBreakStreak: 0,
          lastPerfectDay: dayOnly,
        );
      }
    }

    final updateResult = await _repository.updateStreakStatus(status);
    if (updateResult.isFailure) {
      return Result.failure(updateResult.error);
    }

    return Result.success(status);
  }
}
