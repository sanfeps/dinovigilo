import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/dinosaurs/domain/repositories/egg_repository.dart';

class ResumeAllEggsUseCase {
  final EggRepository _repository;

  const ResumeAllEggsUseCase(this._repository);

  Future<Result<void>> execute() {
    return _repository.resumeAllEggs();
  }
}
