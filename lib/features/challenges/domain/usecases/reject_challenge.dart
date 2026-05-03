import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';

class RejectChallengeUseCase {
  const RejectChallengeUseCase(this._repo);
  final ChallengesRepository _repo;

  Future<Result<void>> execute(String challengeId) =>
      _repo.reject(challengeId);
}
