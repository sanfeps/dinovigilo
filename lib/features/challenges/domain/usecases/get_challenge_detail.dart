import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';

class GetChallengeDetailUseCase {
  const GetChallengeDetailUseCase(this._repo);
  final ChallengesRepository _repo;

  Future<Result<Challenge>> execute(String challengeId) =>
      _repo.getDetail(challengeId);
}
