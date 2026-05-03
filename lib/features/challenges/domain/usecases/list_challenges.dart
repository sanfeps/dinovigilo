import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';

class ListChallengesUseCase {
  const ListChallengesUseCase(this._repo);
  final ChallengesRepository _repo;

  Future<Result<List<Challenge>>> execute() => _repo.list();
}
