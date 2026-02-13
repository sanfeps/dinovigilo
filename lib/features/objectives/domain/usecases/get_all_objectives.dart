import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/domain/repositories/objective_repository.dart';

class GetAllObjectivesUseCase {
  final ObjectiveRepository _repository;

  const GetAllObjectivesUseCase(this._repository);

  Future<Result<List<Objective>>> execute() {
    return _repository.getAll();
  }
}
