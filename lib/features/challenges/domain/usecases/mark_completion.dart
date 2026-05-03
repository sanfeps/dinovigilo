import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge_completion.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';

class MarkCompletionUseCase {
  const MarkCompletionUseCase(this._repo);
  final ChallengesRepository _repo;

  Future<Result<ChallengeCompletion>> execute({
    required String challengeId,
    required String objectiveId,
    required DateTime date,
    required bool completed,
  }) {
    return _repo.markCompletion(
      challengeId: challengeId,
      objectiveId: objectiveId,
      date: date,
      completed: completed,
    );
  }
}
