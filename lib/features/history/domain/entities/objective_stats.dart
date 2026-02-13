import 'package:freezed_annotation/freezed_annotation.dart';

part 'objective_stats.freezed.dart';
part 'objective_stats.g.dart';

@freezed
class ObjectiveStats with _$ObjectiveStats {
  const factory ObjectiveStats({
    required String objectiveId,
    required int totalDays,
    required int completedDays,
  }) = _ObjectiveStats;

  const ObjectiveStats._();

  double get completionRate {
    if (totalDays <= 0) return 0.0;
    return (completedDays / totalDays).clamp(0.0, 1.0);
  }

  factory ObjectiveStats.fromJson(Map<String, dynamic> json) =>
      _$ObjectiveStatsFromJson(json);
}
