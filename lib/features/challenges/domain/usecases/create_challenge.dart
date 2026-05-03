import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';

class CreateChallengeUseCase {
  const CreateChallengeUseCase(this._repo);
  final ChallengesRepository _repo;

  Future<Result<Challenge>> execute({
    required String opponentId,
    required String penaltyObjective,
    required List<NewChallengeObjectiveDraft> objectives,
  }) {
    return _repo.create(
      opponentId: opponentId,
      penaltyObjective: penaltyObjective,
      objectives: objectives,
    );
  }
}
