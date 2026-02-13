import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';

abstract class SprintRepository {
  Future<Result<Sprint?>> getActiveSprint();
  Future<Result<Sprint>> getById(String id);
  Future<Result<Sprint>> create(Sprint sprint);
  Future<Result<void>> update(Sprint sprint);
  Future<Result<void>> deactivateAll();
  Stream<Sprint?> watchActiveSprint();
}
