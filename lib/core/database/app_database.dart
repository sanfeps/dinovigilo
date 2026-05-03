import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:dinovigilo/core/constants/app_constants.dart';
import 'package:dinovigilo/core/constants/dinosaur_species_data.dart';
import 'package:dinovigilo/core/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Objectives,
  Sprints,
  DayObjectiveMappings,
  DailyCompletions,
  DinosaurSpeciesTable,
  Dinosaurs,
  PendingEggs,
  StreakStatusTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with a custom executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDinosaurSpecies();
        await _initializeStreakStatus();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Recreate PendingEggs with new columns
          await m.deleteTable('pending_eggs');
          await m.createTable(pendingEggs);
        }
        if (from < 3) {
          await m.addColumn(
            streakStatusTable,
            streakStatusTable.preBreakStreak,
          );
        }
        if (from < 4) {
          await customStatement(
            "ALTER TABLE sprints ADD COLUMN duration_days INTEGER NOT NULL DEFAULT 14",
          );
        }
        if (from < 5) {
          // Drop duration_days column and clean up day mappings
          // outside the weekly cycle (dayOfSprint >= 7).
          await customStatement(
            'DELETE FROM day_objective_mappings WHERE day_of_sprint >= 7',
          );
          await customStatement('ALTER TABLE sprints DROP COLUMN duration_days');
        }
        if (from < 6) {
          // Switch day_of_sprint from start-date offset to weekday index
          // (0=Mon..6=Sun) using each sprint's old start_date, then drop it.
          await customStatement('''
            UPDATE day_objective_mappings
            SET day_of_sprint = (day_of_sprint + (
              SELECT ((CAST(strftime('%w', start_date, 'unixepoch') AS INTEGER) + 6) % 7)
              FROM sprints WHERE sprints.id = day_objective_mappings.sprint_id
            )) % 7
          ''');
          await customStatement('ALTER TABLE sprints DROP COLUMN start_date');
        }
        if (from < 7) {
          await m.addColumn(objectives, objectives.isPenalty);
          await m.addColumn(objectives, objectives.expiresAt);
        }
      },
    );
  }

  Future<void> _seedDinosaurSpecies() async {
    await batch((batch) {
      batch.insertAll(
        dinosaurSpeciesTable,
        DinosaurSpeciesData.allSpecies
            .map(
              (species) => DinosaurSpeciesTableCompanion.insert(
                id: species.id,
                name: species.name,
                emoji: species.emoji,
                rarity: species.rarity.name,
                description: species.description,
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> _initializeStreakStatus() async {
    await into(streakStatusTable).insert(
      StreakStatusTableCompanion.insert(
        currentStreak: 0,
        totalPerfectDays: 0,
        longestStreak: 0,
        isActive: true,
        recoveryDaysNeeded: 0,
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
