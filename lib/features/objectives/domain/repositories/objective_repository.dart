import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';

abstract class ObjectiveRepository {
  Future<Result<List<Objective>>> getAll();
  Future<Result<Objective>> getById(String id);
  Future<Result<Objective>> create(Objective objective);
  Future<Result<void>> update(Objective objective);
  Future<Result<void>> delete(String id);
  Stream<List<Objective>> watchAll();
}
