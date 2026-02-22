import 'package:drift/drift.dart';

class Objectives extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Sprints extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startDate => dateTime()();
  BoolColumn get isActive => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DayObjectiveMappingRow')
class DayObjectiveMappings extends Table {
  TextColumn get id => text()();
  TextColumn get sprintId =>
      text().references(Sprints, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayOfSprint => integer()();
  TextColumn get objectiveId =>
      text().references(Objectives, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyCompletionRow')
class DailyCompletions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get objectiveId =>
      text().references(Objectives, #id, onDelete: KeyAction.cascade)();
  BoolColumn get completed => boolean()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {date, objectiveId},
      ];
}

@DataClassName('DinosaurSpeciesRow')
class DinosaurSpeciesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text()();
  TextColumn get rarity => text()();
  TextColumn get description => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'dinosaur_species';
}

class Dinosaurs extends Table {
  TextColumn get id => text()();
  TextColumn get speciesId =>
      text().references(DinosaurSpeciesTable, #id)();
  DateTimeColumn get hatchedAt => dateTime()();
  IntColumn get streakDayWhenHatched => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PendingEggRow')
class PendingEggs extends Table {
  TextColumn get id => text()();
  TextColumn get rarity => text()();
  IntColumn get totalDaysNeeded => integer()();
  IntColumn get daysIncubated =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isPaused =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StreakStatusRow')
class StreakStatusTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get currentStreak => integer()();
  IntColumn get totalPerfectDays => integer()();
  IntColumn get longestStreak => integer()();
  DateTimeColumn get lastPerfectDay => dateTime().nullable()();
  BoolColumn get isActive => boolean()();
  IntColumn get recoveryDaysNeeded => integer()();
  IntColumn get preBreakStreak =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'streak_status';
}
