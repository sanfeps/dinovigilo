import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/domain/repositories/objective_repository.dart';
import 'package:dinovigilo/features/sprint/domain/repositories/sprint_repository.dart';

class GetObjectivesForDayUseCase {
  final SprintRepository _sprintRepository;
  final ObjectiveRepository _objectiveRepository;

  const GetObjectivesForDayUseCase(
    this._sprintRepository,
    this._objectiveRepository,
  );

  Future<Result<List<Objective>>> execute(DateTime date) async {
    final sprintResult = await _sprintRepository.getActiveSprint();
    if (sprintResult.isFailure) return Result.failure(sprintResult.error);

    final sprint = sprintResult.data;
    if (sprint == null) {
      return Result.failure(const NotFoundFailure('No active sprint'));
    }

    if (!sprint.isDateInSprint(date)) {
      return Result.success(const []);
    }

    final dayOfSprint = sprint.getDayOfSprint(date);
    final objectiveIds = sprint.getObjectiveIdsForDay(dayOfSprint);

    if (objectiveIds.isEmpty) {
      return Result.success(const []);
    }

    final allObjectivesResult = await _objectiveRepository.getAll();
    if (allObjectivesResult.isFailure) {
      return Result.failure(allObjectivesResult.error);
    }

    final objectives = allObjectivesResult.data
        .where((obj) => objectiveIds.contains(obj.id))
        .toList();

    return Result.success(objectives);
  }
}
