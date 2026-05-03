import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge_completion.dart';

enum DayStatus {
  /// All objectives marked complete for that user on that day.
  done,

  /// Day is over (past midnight) and at least one objective was missed.
  failed,

  /// Day is the current local day; user can still mark missing objectives.
  pending,

  /// Day is later in the week.
  future,
}

class DayCell {
  const DayCell({required this.date, required this.status});

  final DateTime date;
  final DayStatus status;
}

class ChallengeProgress {
  const ChallengeProgress._();

  /// Builds a 7-cell row of [DayCell]s for [userId], one per day from
  /// [Challenge.weekStart] (Monday) through Sunday. Week boundaries are read
  /// from the challenge in UTC; comparison against [now] uses local time so
  /// "today" matches the device clock.
  static List<DayCell> daysFor({
    required Challenge challenge,
    required String userId,
    required DateTime now,
  }) {
    final start = challenge.weekStart;
    if (start == null) return const [];

    final localStart = _midnight(start.toLocal());
    final today = _midnight(now);

    return List.generate(7, (i) {
      final day = localStart.add(Duration(days: i));
      return DayCell(
        date: day,
        status: statusFor(
          challenge: challenge,
          userId: userId,
          day: day,
          today: today,
        ),
      );
    });
  }

  /// Status of one (user, day) pair. [day] and [today] must be local-midnight.
  static DayStatus statusFor({
    required Challenge challenge,
    required String userId,
    required DateTime day,
    required DateTime today,
  }) {
    final allMarked = _allObjectivesMarked(challenge, userId, day);
    if (allMarked) return DayStatus.done;
    if (day.isAfter(today)) return DayStatus.future;
    if (_isSameDay(day, today)) return DayStatus.pending;
    return DayStatus.failed;
  }

  /// Number of failed days for [userId] in the current week so far.
  static int failedDayCount({
    required Challenge challenge,
    required String userId,
    required DateTime now,
  }) {
    return daysFor(challenge: challenge, userId: userId, now: now)
        .where((c) => c.status == DayStatus.failed)
        .length;
  }

  /// IDs of objectives the given user has marked complete on [day].
  static Set<String> markedObjectiveIdsFor({
    required Challenge challenge,
    required String userId,
    required DateTime day,
  }) {
    final localDay = _midnight(day);
    return challenge.completions
        .where((c) =>
            c.completed &&
            c.userId == userId &&
            _isSameDay(c.date.toLocal(), localDay))
        .map((c) => c.objectiveId)
        .toSet();
  }

  static bool _allObjectivesMarked(
    Challenge challenge,
    String userId,
    DateTime day,
  ) {
    if (challenge.objectives.isEmpty) return false;
    final marked =
        markedObjectiveIdsFor(challenge: challenge, userId: userId, day: day);
    return challenge.objectives.every((o) => marked.contains(o.id));
  }

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

extension ChallengeCompletionsX on List<ChallengeCompletion> {
  /// Replaces or inserts a completion in-place by (userId, objectiveId, date).
  /// Returns a new list; useful for optimistic updates.
  List<ChallengeCompletion> upsert(ChallengeCompletion incoming) {
    final idx = indexWhere((c) =>
        c.userId == incoming.userId &&
        c.objectiveId == incoming.objectiveId &&
        c.date.toUtc() == incoming.date.toUtc());
    if (idx == -1) return [...this, incoming];
    final next = [...this];
    next[idx] = incoming;
    return next;
  }
}
