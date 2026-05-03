import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';

class CancelChallengeUseCase {
  const CancelChallengeUseCase(this._repo);
  final ChallengesRepository _repo;

  Future<Result<Challenge>> execute(String challengeId) =>
      _repo.cancel(challengeId);
}
