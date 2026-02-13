import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/dinosaurs/domain/repositories/egg_repository.dart';

class PauseAllEggsUseCase {
  final EggRepository _repository;

  const PauseAllEggsUseCase(this._repository);

  Future<Result<void>> execute() {
    return _repository.pauseAllEggs();
  }
}
