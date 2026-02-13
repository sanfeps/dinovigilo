import 'package:drift/drift.dart';
import 'package:dinovigilo/core/database/app_database.dart' hide Dinosaur;
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_rarity.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_species.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/pending_egg.dart';

class EggLocalDatasource {
  final AppDatabase _db;

  const EggLocalDatasource(this._db);

  // --- PendingEggs ---

  Future<List<PendingEgg>> getPendingEggs() async {
    final rows = await _db.select(_db.pendingEggs).get();
    return rows.map(_eggRowToEntity).toList();
  }

  Future<PendingEgg> insertEgg(PendingEgg egg) async {
    await _db.into(_db.pendingEggs).insert(
          PendingEggsCompanion.insert(
            id: egg.id,
            rarity: egg.rarity.name,
            totalDaysNeeded: egg.totalDaysNeeded,
          ),
        );
    return egg;
  }

  Future<void> hatchEgg(String eggId, Dinosaur dinosaur) async {
    await _db.transaction(() async {
      await (_db.delete(_db.pendingEggs)
            ..where((t) => t.id.equals(eggId)))
          .go();
      await _db.into(_db.dinosaurs).insert(
            DinosaursCompanion.insert(
              id: dinosaur.id,
              speciesId: dinosaur.speciesId,
              hatchedAt: dinosaur.hatchedAt,
              streakDayWhenHatched: dinosaur.streakDayWhenHatched,
            ),
          );
    });
  }

  Future<void> pauseAllEggs() async {
    await _db.update(_db.pendingEggs).write(
          const PendingEggsCompanion(isPaused: Value(true)),
        );
  }

  Future<void> resumeAllEggs() async {
    await _db.update(_db.pendingEggs).write(
          const PendingEggsCompanion(isPaused: Value(false)),
        );
  }

  Future<void> advanceAllEggs() async {
    await _db.customUpdate(
      'UPDATE pending_eggs SET days_incubated = days_incubated + 1 '
      'WHERE is_paused = 0',
      updates: {_db.pendingEggs},
      updateKind: UpdateKind.update,
    );
  }

  Stream<List<PendingEgg>> watchPendingEggs() {
    return _db.select(_db.pendingEggs).watch().map(
          (rows) => rows.map(_eggRowToEntity).toList(),
        );
  }

  // --- Dinosaurs ---

  Future<List<Dinosaur>> getAllDinosaurs() async {
    final rows = await _db.select(_db.dinosaurs).get();
    return rows.map(_dinosaurRowToEntity).toList();
  }

  Stream<List<Dinosaur>> watchDinosaurs() {
    return _db.select(_db.dinosaurs).watch().map(
          (rows) => rows.map(_dinosaurRowToEntity).toList(),
        );
  }

  // --- Species ---

  Future<List<DinosaurSpecies>> getSpeciesByRarity(
    DinosaurRarity rarity,
  ) async {
    final rows = await (_db.select(_db.dinosaurSpeciesTable)
          ..where((t) => t.rarity.equals(rarity.name)))
        .get();
    return rows.map(_speciesRowToEntity).toList();
  }

  Future<Set<String>> getExistingSpeciesIds() async {
    final rows = await _db.select(_db.dinosaurs).get();
    return rows.map((r) => r.speciesId).toSet();
  }

  // --- Mappers ---

  PendingEgg _eggRowToEntity(PendingEggRow row) {
    return PendingEgg(
      id: row.id,
      rarity: DinosaurRarity.values.byName(row.rarity),
      totalDaysNeeded: row.totalDaysNeeded,
      daysIncubated: row.daysIncubated,
      isPaused: row.isPaused,
    );
  }

  Dinosaur _dinosaurRowToEntity(dynamic row) {
    return Dinosaur(
      id: row.id as String,
      speciesId: row.speciesId as String,
      hatchedAt: row.hatchedAt as DateTime,
      streakDayWhenHatched: row.streakDayWhenHatched as int,
    );
  }

  DinosaurSpecies _speciesRowToEntity(DinosaurSpeciesRow row) {
    return DinosaurSpecies(
      id: row.id,
      name: row.name,
      emoji: row.emoji,
      rarity: DinosaurRarity.values.byName(row.rarity),
      description: row.description,
    );
  }
}
