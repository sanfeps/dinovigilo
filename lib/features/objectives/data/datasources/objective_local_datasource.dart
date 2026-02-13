import 'package:drift/drift.dart';
import 'package:dinovigilo/core/database/app_database.dart' hide Objective;
import 'package:dinovigilo/core/error/exceptions.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';

class ObjectiveLocalDatasource {
  final AppDatabase _db;

  const ObjectiveLocalDatasource(this._db);

  Future<List<Objective>> getAll() async {
    final rows = await _db.select(_db.objectives).get();
    return rows.map(_rowToEntity).toList();
  }

  Future<Objective> getById(String id) async {
    final row = await (_db.select(_db.objectives)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (row == null) {
      throw NotFoundException('Objective with id $id not found');
    }

    return _rowToEntity(row);
  }

  Future<Objective> insert(Objective objective) async {
    await _db.into(_db.objectives).insert(
          ObjectivesCompanion.insert(
            id: objective.id,
            title: objective.title,
            description: Value(objective.description),
            createdAt: objective.createdAt,
          ),
        );
    return objective;
  }

  Future<void> updateObj(Objective objective) async {
    final count = await (_db.update(_db.objectives)
          ..where((t) => t.id.equals(objective.id)))
        .write(
      ObjectivesCompanion(
        title: Value(objective.title),
        description: Value(objective.description),
      ),
    );

    if (count == 0) {
      throw NotFoundException('Objective with id ${objective.id} not found');
    }
  }

  Future<void> deleteObj(String id) async {
    final count = await (_db.delete(_db.objectives)
          ..where((t) => t.id.equals(id)))
        .go();

    if (count == 0) {
      throw NotFoundException('Objective with id $id not found');
    }
  }

  Stream<List<Objective>> watchAll() {
    return _db.select(_db.objectives).watch().map(
          (rows) => rows.map(_rowToEntity).toList(),
        );
  }

  Objective _rowToEntity(dynamic row) {
    return Objective(
      id: row.id as String,
      title: row.title as String,
      description: row.description as String?,
      createdAt: row.createdAt as DateTime,
    );
  }
}
