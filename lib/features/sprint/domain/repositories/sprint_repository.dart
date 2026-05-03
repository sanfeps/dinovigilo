import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/sprint/domain/entities/day_objective_mapping.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';

abstract class SprintRepository {
  Future<Result<Sprint?>> getActiveSprint();
  Future<Result<Sprint>> getById(String id);
  Future<Result<Sprint>> create(Sprint sprint);
  Future<Result<void>> update(Sprint sprint);
  Future<Result<void>> deactivateAll();
  Future<Result<void>> addMappings(
    String sprintId,
    List<DayObjectiveMapping> mappings,
  );
  Stream<Sprint?> watchActiveSprint();
}
