import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/domain/repositories/objective_repository.dart';

class UpdateObjectiveUseCase {
  final ObjectiveRepository _repository;

  const UpdateObjectiveUseCase(this._repository);

  Future<Result<void>> execute(Objective objective) async {
    if (objective.title.trim().isEmpty) {
      return Result.failure(
        const ValidationFailure('Objective title cannot be empty'),
      );
    }

    return _repository.update(objective.copyWith(
      title: objective.title.trim(),
      description: objective.description?.trim(),
    ));
  }
}
