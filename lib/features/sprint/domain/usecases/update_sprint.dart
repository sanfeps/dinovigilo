import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/sprint/domain/entities/day_objective_mapping.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';
import 'package:dinovigilo/features/sprint/domain/repositories/sprint_repository.dart';
import 'package:uuid/uuid.dart';

class UpdateSprintUseCase {
  final SprintRepository _repository;

  const UpdateSprintUseCase(this._repository);

  Future<Result<void>> execute({
    required Sprint sprint,
    required Map<int, List<String>> dayObjectiveIds,
  }) async {
    final hasAnyObjective =
        dayObjectiveIds.values.any((ids) => ids.isNotEmpty);
    if (!hasAnyObjective) {
      return Result.failure(
        const ValidationFailure('At least one objective must be assigned'),
      );
    }

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

    final updated = sprint.copyWith(dayMappings: mappings);
    return _repository.update(updated);
  }
}
