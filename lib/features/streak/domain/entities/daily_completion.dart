import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_completion.freezed.dart';
part 'daily_completion.g.dart';

@freezed
class DailyCompletion with _$DailyCompletion {
  const factory DailyCompletion({
    required String id,
    required DateTime date,
    required String objectiveId,
    required bool completed,
    DateTime? completedAt,
  }) = _DailyCompletion;

  factory DailyCompletion.fromJson(Map<String, dynamic> json) =>
      _$DailyCompletionFromJson(json);
}
