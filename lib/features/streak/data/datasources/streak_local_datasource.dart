import 'package:drift/drift.dart';
import 'package:dinovigilo/core/database/app_database.dart' hide Objective, Sprint;
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:uuid/uuid.dart';

class StreakLocalDatasource {
  final AppDatabase _db;

  const StreakLocalDatasource(this._db);

  // --- StreakStatus (singleton, id=1) ---

  Future<StreakStatus> getStreakStatus() async {
    final row = await (_db.select(_db.streakStatusTable)
          ..where((t) => t.id.equals(1)))
        .getSingle();
    return _streakRowToEntity(row);
  }

  Future<void> updateStreakStatus(StreakStatus status) async {
    await (_db.update(_db.streakStatusTable)
          ..where((t) => t.id.equals(1)))
        .write(StreakStatusTableCompanion(
      currentStreak: Value(status.currentStreak),
      totalPerfectDays: Value(status.totalPerfectDays),
      longestStreak: Value(status.longestStreak),
      lastPerfectDay: Value(status.lastPerfectDay),
      isActive: Value(status.isActive),
      recoveryDaysNeeded: Value(status.recoveryDaysNeeded),
    ));
  }

  Stream<StreakStatus> watchStreakStatus() {
    final query = _db.select(_db.streakStatusTable)
      ..where((t) => t.id.equals(1));
    return query.watchSingle().map(_streakRowToEntity);
  }

  // --- DailyCompletions ---

  Future<List<DailyCompletion>> getCompletionsForDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final rows = await (_db.select(_db.dailyCompletions)
          ..where((t) => t.date.equals(dateOnly)))
        .get();
    return rows.map(_completionRowToEntity).toList();
  }

  Stream<List<DailyCompletion>> watchCompletionsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = _db.select(_db.dailyCompletions)
      ..where((t) => t.date.equals(dateOnly));
    return query.watch().map(
          (rows) => rows.map(_completionRowToEntity).toList(),
        );
  }

  Future<DailyCompletion> toggleCompletion(
    String completionId,
    bool completed,
  ) async {
    final completedAt = completed ? DateTime.now() : null;
    await (_db.update(_db.dailyCompletions)
          ..where((t) => t.id.equals(completionId)))
        .write(DailyCompletionsCompanion(
      completed: Value(completed),
      completedAt: Value(completedAt),
    ));

    final row = await (_db.select(_db.dailyCompletions)
          ..where((t) => t.id.equals(completionId)))
        .getSingle();
    return _completionRowToEntity(row);
  }

  /// Creates DailyCompletion rows for the given date and objective IDs,
  /// skipping any that already exist (idempotent).
  Future<void> ensureCompletionsForDate(
    DateTime date,
    List<String> objectiveIds,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    const uuid = Uuid();

    await _db.transaction(() async {
      final existing = await (_db.select(_db.dailyCompletions)
            ..where((t) => t.date.equals(dateOnly)))
          .get();

      final existingObjectiveIds =
          existing.map((r) => r.objectiveId).toSet();

      for (final objectiveId in objectiveIds) {
        if (!existingObjectiveIds.contains(objectiveId)) {
          await _db.into(_db.dailyCompletions).insert(
                DailyCompletionsCompanion.insert(
                  id: uuid.v4(),
                  date: dateOnly,
                  objectiveId: objectiveId,
                  completed: false,
                ),
              );
        }
      }
    });
  }

  Future<bool> isDayPerfect(DateTime date) async {
    final completions = await getCompletionsForDate(date);
    if (completions.isEmpty) return false;
    return completions.every((c) => c.completed);
  }

  /// Get all completions for a date range, grouped by date.
  Future<Map<DateTime, List<DailyCompletion>>> getCompletionsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    final rows = await (_db.select(_db.dailyCompletions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(startOnly) &
              t.date.isSmallerOrEqualValue(endOnly)))
        .get();

    final map = <DateTime, List<DailyCompletion>>{};
    for (final row in rows) {
      final dateKey = DateTime(row.date.year, row.date.month, row.date.day);
      map.putIfAbsent(dateKey, () => []).add(_completionRowToEntity(row));
    }
    return map;
  }

  /// Get per-objective completion stats (total assigned days + completed days).
  Future<List<({String objectiveId, int totalDays, int completedDays})>>
      getObjectiveCompletionStats() async {
    final rows = await _db.select(_db.dailyCompletions).get();

    final totals = <String, int>{};
    final completed = <String, int>{};

    for (final row in rows) {
      totals[row.objectiveId] = (totals[row.objectiveId] ?? 0) + 1;
      if (row.completed) {
        completed[row.objectiveId] = (completed[row.objectiveId] ?? 0) + 1;
      }
    }

    return totals.entries.map((e) {
      return (
        objectiveId: e.key,
        totalDays: e.value,
        completedDays: completed[e.key] ?? 0,
      );
    }).toList();
  }

  // --- Mappers ---

  StreakStatus _streakRowToEntity(StreakStatusRow row) {
    return StreakStatus(
      currentStreak: row.currentStreak,
      totalPerfectDays: row.totalPerfectDays,
      longestStreak: row.longestStreak,
      lastPerfectDay: row.lastPerfectDay,
      isActive: row.isActive,
      recoveryDaysNeeded: row.recoveryDaysNeeded,
    );
  }

  DailyCompletion _completionRowToEntity(DailyCompletionRow row) {
    return DailyCompletion(
      id: row.id,
      date: row.date,
      objectiveId: row.objectiveId,
      completed: row.completed,
      completedAt: row.completedAt,
    );
  }
}
