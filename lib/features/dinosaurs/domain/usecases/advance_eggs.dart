import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/dinosaurs/domain/repositories/egg_repository.dart';

class AdvanceEggsUseCase {
  final EggRepository _repository;

  const AdvanceEggsUseCase(this._repository);

  /// Increment daysIncubated by 1 for all non-paused eggs.
  Future<Result<void>> execute() {
    return _repository.advanceAllEggs();
  }
}
