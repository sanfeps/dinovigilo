import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge_completion.dart';

class NewChallengeObjectiveDraft {
  const NewChallengeObjectiveDraft({
    required this.title,
    this.description = '',
  });

  final String title;
  final String description;
}

abstract class ChallengesRepository {
  Future<Result<List<Challenge>>> list();

  Future<Result<Challenge>> getDetail(String challengeId);

  Future<Result<Challenge>> create({
    required String opponentId,
    required String penaltyObjective,
    required List<NewChallengeObjectiveDraft> objectives,
  });

  Future<Result<Challenge>> accept(String challengeId);

  Future<Result<void>> reject(String challengeId);

  Future<Result<Challenge>> cancel(String challengeId);

  Future<Result<ChallengeCompletion>> markCompletion({
    required String challengeId,
    required String objectiveId,
    required DateTime date,
    required bool completed,
  });

  Future<Result<Challenge>> closeChallenge({
    required String challengeId,
    required String? winnerId,
    required String? loserId,
    required bool isTie,
  });

  Future<Result<Challenge>> markPenaltyApplied(String challengeId);
}
