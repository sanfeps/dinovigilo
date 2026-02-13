import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/repositories/egg_repository.dart';

class GetCollectionUseCase {
  final EggRepository _repository;

  const GetCollectionUseCase(this._repository);

  Future<Result<List<Dinosaur>>> execute() {
    return _repository.getAllDinosaurs();
  }
}
