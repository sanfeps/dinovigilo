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
  }) = _StreakStatus;

  const StreakStatus._();

  bool get isInRecoveryMode => !isActive && recoveryDaysNeeded > 0;
  bool get isHealthy => isActive && currentStreak > 0;

  factory StreakStatus.fromJson(Map<String, dynamic> json) =>
      _$StreakStatusFromJson(json);
}
