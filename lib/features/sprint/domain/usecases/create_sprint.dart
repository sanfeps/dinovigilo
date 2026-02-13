import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/sprint/domain/entities/day_objective_mapping.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';
import 'package:dinovigilo/features/sprint/domain/repositories/sprint_repository.dart';
import 'package:uuid/uuid.dart';

class CreateSprintUseCase {
  final SprintRepository _repository;

  const CreateSprintUseCase(this._repository);

  Future<Result<Sprint>> execute({
    required DateTime startDate,
    required Map<int, List<String>> dayObjectiveIds,
  }) async {
    if (dayObjectiveIds.isEmpty) {
      return Result.failure(
        const ValidationFailure('At least one day must have objectives assigned'),
      );
    }

    final hasAnyObjective =
        dayObjectiveIds.values.any((ids) => ids.isNotEmpty);
    if (!hasAnyObjective) {
      return Result.failure(
        const ValidationFailure('At least one objective must be assigned'),
      );
    }

    // Deactivate existing sprints
    final deactivateResult = await _repository.deactivateAll();
    if (deactivateResult.isFailure) return Result.failure(deactivateResult.error);

    const uuid = Uuid();

    final mappings = <DayObjectiveMapping>[];
    for (final entry in dayObjectiveIds.entries) {
      for (final objectiveId in entry.value) {
        mappings.add(DayObjectiveMapping(
          id: uuid.v4(),
          dayOfSprint: entry.key,
          objectiveId: objectiveId,
        ));
      }
    }

    final sprint = Sprint(
      id: uuid.v4(),
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      dayMappings: mappings,
      isActive: true,
    );

    return _repository.create(sprint);
  }
}
