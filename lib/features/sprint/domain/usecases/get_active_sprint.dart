import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';
import 'package:dinovigilo/features/sprint/domain/repositories/sprint_repository.dart';

class GetActiveSprintUseCase {
  final SprintRepository _repository;

  const GetActiveSprintUseCase(this._repository);

  Future<Result<Sprint?>> execute() {
    return _repository.getActiveSprint();
  }
}
