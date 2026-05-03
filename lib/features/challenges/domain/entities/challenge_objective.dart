import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge_objective.freezed.dart';
part 'challenge_objective.g.dart';

@freezed
class ChallengeObjective with _$ChallengeObjective {
  const factory ChallengeObjective({
    required String id,
    required String title,
    @Default('') String description,
    required int sortOrder,
  }) = _ChallengeObjective;

  factory ChallengeObjective.fromJson(Map<String, dynamic> json) =>
      _$ChallengeObjectiveFromJson(json);
}
