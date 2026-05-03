import 'package:dinovigilo/features/challenges/domain/entities/challenge_completion.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge_objective.dart';
import 'package:dinovigilo/features/friends/domain/entities/friend.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge.freezed.dart';
part 'challenge.g.dart';

enum ChallengeStatus {
  proposed,
  active,
  completed,
  cancelled,
  rejected;

  static ChallengeStatus fromString(String raw) {
    return ChallengeStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ChallengeStatus.proposed,
    );
  }
}

@freezed
class Challenge with _$Challenge {
  const factory Challenge({
    required String id,
    required ChallengeStatus status,
    required Friend opponent,
    required bool iAmProposer,
    required String penaltyObjective,
    required List<ChallengeObjective> objectives,
    @Default(<ChallengeCompletion>[])
    List<ChallengeCompletion> completions,
    DateTime? weekStart,
    DateTime? weekEnd,
    String? winnerId,
    String? loserId,
    @Default(false) bool isTie,
    @Default(false) bool penaltyApplied,
    required DateTime createdAt,
  }) = _Challenge;

  factory Challenge.fromJson(Map<String, dynamic> json) =>
      _$ChallengeFromJson(json);
}
