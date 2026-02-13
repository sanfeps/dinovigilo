import 'package:drift/drift.dart';
import 'package:dinovigilo/core/database/app_database.dart' hide Sprint;
import 'package:dinovigilo/core/error/exceptions.dart';
import 'package:dinovigilo/features/sprint/domain/entities/day_objective_mapping.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';

class SprintLocalDatasource {
  final AppDatabase _db;

  const SprintLocalDatasource(this._db);

  Future<Sprint?> getActiveSprint() async {
    final row = await (_db.select(_db.sprints)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();

    if (row == null) return null;

    final mappings = await _getMappingsForSprint(row.id);
    return _rowToEntity(row, mappings);
  }

  Future<Sprint> getById(String id) async {
    final row = await (_db.select(_db.sprints)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (row == null) {
      throw NotFoundException('Sprint with id $id not found');
    }

    final mappings = await _getMappingsForSprint(id);
    return _rowToEntity(row, mappings);
  }

  Future<Sprint> insert(Sprint sprint) async {
    await _db.transaction(() async {
      await _db.into(_db.sprints).insert(
            SprintsCompanion.insert(
              id: sprint.id,
              startDate: sprint.startDate,
              isActive: sprint.isActive,
            ),
          );

      for (final mapping in sprint.dayMappings) {
        await _db.into(_db.dayObjectiveMappings).insert(
              DayObjectiveMappingsCompanion.insert(
                id: mapping.id,
                sprintId: sprint.id,
                dayOfSprint: mapping.dayOfSprint,
                objectiveId: mapping.objectiveId,
              ),
            );
      }
    });

    return sprint;
  }

  Future<void> updateSprint(Sprint sprint) async {
    await _db.transaction(() async {
      // Update the sprint row
      await (_db.update(_db.sprints)
            ..where((t) => t.id.equals(sprint.id)))
          .write(
        SprintsCompanion(
          startDate: Value(sprint.startDate),
          isActive: Value(sprint.isActive),
        ),
      );

      // Delete old mappings
      await (_db.delete(_db.dayObjectiveMappings)
            ..where((t) => t.sprintId.equals(sprint.id)))
          .go();

      // Insert new mappings
      for (final mapping in sprint.dayMappings) {
        await _db.into(_db.dayObjectiveMappings).insert(
              DayObjectiveMappingsCompanion.insert(
                id: mapping.id,
                sprintId: sprint.id,
                dayOfSprint: mapping.dayOfSprint,
                objectiveId: mapping.objectiveId,
              ),
            );
      }
    });
  }

  Future<void> deactivateAll() async {
    await (_db.update(_db.sprints)).write(
      const SprintsCompanion(isActive: Value(false)),
    );
  }

  Stream<Sprint?> watchActiveSprint() {
    final sprintQuery = _db.select(_db.sprints)
      ..where((t) => t.isActive.equals(true));

    return sprintQuery.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      final mappings = await _getMappingsForSprint(row.id);
      return _rowToEntity(row, mappings);
    });
  }

  Future<List<DayObjectiveMapping>> _getMappingsForSprint(
    String sprintId,
  ) async {
    final rows = await (_db.select(_db.dayObjectiveMappings)
          ..where((t) => t.sprintId.equals(sprintId)))
        .get();

    return rows
        .map((row) => DayObjectiveMapping(
              id: row.id,
              dayOfSprint: row.dayOfSprint,
              objectiveId: row.objectiveId,
            ))
        .toList();
  }

  Sprint _rowToEntity(dynamic row, List<DayObjectiveMapping> mappings) {
    return Sprint(
      id: row.id as String,
      startDate: row.startDate as DateTime,
      dayMappings: mappings,
      isActive: row.isActive as bool,
    );
  }
}
