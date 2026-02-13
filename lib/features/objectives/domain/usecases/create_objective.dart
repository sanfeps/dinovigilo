import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/domain/repositories/objective_repository.dart';
import 'package:uuid/uuid.dart';

class CreateObjectiveUseCase {
  final ObjectiveRepository _repository;

  const CreateObjectiveUseCase(this._repository);

  Future<Result<Objective>> execute({
    required String title,
    String? description,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return Result.failure(
        const ValidationFailure('Objective title cannot be empty'),
      );
    }

    final objective = Objective(
      id: const Uuid().v4(),
      title: trimmedTitle,
      description: description?.trim(),
      createdAt: DateTime.now(),
    );

    return _repository.create(objective);
  }
}
