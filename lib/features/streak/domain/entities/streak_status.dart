import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak_status.freezed.dart';
part 'streak_status.g.dart';

@freezed
class StreakStatus with _$StreakStatus {
  const factory StreakStatus({
    required int currentStreak,
    required int totalPerfectDays,
    required int longestStreak,
    DateTime? lastPerfectDay,
    required bool isActive,
    required int recoveryDaysNeeded,
    @Default(0) int preBreakStreak,
  }) = _StreakStatus;

  const StreakStatus._();

  bool get isInRecoveryMode => !isActive && recoveryDaysNeeded > 0;
  bool get isHealthy => isActive && currentStreak > 0;

  /// True when the yesterday-buffer grace card should be offered.
  /// Conditions: streak is inactive, preBreakStreak was saved, and
  /// lastPerfectDay (= the day that was missed) was exactly yesterday.
  bool get isYesterdayBufferAvailable {
    if (isActive || preBreakStreak == 0 || lastPerfectDay == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final lastDay = DateTime(
      lastPerfectDay!.year,
      lastPerfectDay!.month,
      lastPerfectDay!.day,
    );
    return todayOnly.difference(lastDay).inDays == 1;
  }

  factory StreakStatus.fromJson(Map<String, dynamic> json) =>
      _$StreakStatusFromJson(json);
}
