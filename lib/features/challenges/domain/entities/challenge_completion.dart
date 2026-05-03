import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge_completion.freezed.dart';
part 'challenge_completion.g.dart';

@freezed
class ChallengeCompletion with _$ChallengeCompletion {
  const factory ChallengeCompletion({
    required String id,
    required String userId,
    required String objectiveId,
    required DateTime date,
    required bool completed,
  }) = _ChallengeCompletion;

  factory ChallengeCompletion.fromJson(Map<String, dynamic> json) =>
      _$ChallengeCompletionFromJson(json);
}
