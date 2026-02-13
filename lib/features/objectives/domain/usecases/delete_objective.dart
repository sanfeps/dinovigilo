import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/objectives/domain/repositories/objective_repository.dart';

class DeleteObjectiveUseCase {
  final ObjectiveRepository _repository;

  const DeleteObjectiveUseCase(this._repository);

  Future<Result<void>> execute(String id) {
    return _repository.delete(id);
  }
}
