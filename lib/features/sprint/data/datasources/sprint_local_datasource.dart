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
          isActive: Value(sprint.isActive),
        ),
      );

      // System-managed penalty objectives are invisible to the user but
      // should survive an edit of the sprint (their mappings would otherwise
      // be wiped here and the penalty would silently disappear before the
      // 7-day window ends).
      final penaltyIds = (await (_db.select(_db.objectives)
                ..where((t) => t.isPenalty.equals(true)))
              .get())
          .map((o) => o.id)
          .toSet();

      await (_db.delete(_db.dayObjectiveMappings)
            ..where((t) =>
                t.sprintId.equals(sprint.id) &
                t.objectiveId.isNotIn(penaltyIds)))
          .go();

      // Insert new mappings, but skip any that would conflict with surviving
      // penalty mappings (defensive — the UI never lets the user pick them).
      for (final mapping in sprint.dayMappings) {
        if (penaltyIds.contains(mapping.objectiveId)) continue;
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

  /// Inserts the supplied mappings into [sprintId] without touching existing
  /// rows. Used by penalty injection so we don't wipe the user's normal
  /// objective layout.
  Future<void> addMappings(
    String sprintId,
    List<DayObjectiveMapping> mappings,
  ) async {
    await _db.transaction(() async {
      for (final mapping in mappings) {
        await _db.into(_db.dayObjectiveMappings).insert(
              DayObjectiveMappingsCompanion.insert(
                id: mapping.id,
                sprintId: sprintId,
                dayOfSprint: mapping.dayOfSprint,
                objectiveId: mapping.objectiveId,
              ),
            );
      }
    });
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
      dayMappings: mappings,
      isActive: row.isActive as bool,
    );
  }
}
