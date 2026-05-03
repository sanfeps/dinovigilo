import 'package:pocketbase/pocketbase.dart';

import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge_completion.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge_objective.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';
import 'package:dinovigilo/features/friends/data/datasources/friends_remote_datasource.dart';
import 'package:dinovigilo/features/friends/domain/entities/friend.dart';

class ChallengesRemoteDatasource {
  ChallengesRemoteDatasource(this._pb);

  final PocketBase _pb;

  String _requireUserId() {
    final model = _pb.authStore.model;
    if (model is RecordModel) return model.id;
    throw const NotSignedInException();
  }

  Future<List<Challenge>> list() async {
    final me = _requireUserId();
    final records = await _pb.collection('challenges').getFullList(
          filter: 'proposerId = "$me" || opponentId = "$me"',
          expand: 'proposerId,opponentId',
          sort: '-created',
        );
    if (records.isEmpty) return const [];

    final ids = records.map((r) => r.id).toList(growable: false);
    final filter = ids.map((id) => 'challengeId = "$id"').join(' || ');
    final objectiveRecords = await _pb
        .collection('challenge_objectives')
        .getFullList(filter: filter, sort: 'sortOrder');

    final byChallenge = <String, List<ChallengeObjective>>{};
    for (final r in objectiveRecords) {
      final cid = r.getStringValue('challengeId');
      byChallenge.putIfAbsent(cid, () => []).add(_objectiveFromRecord(r));
    }

    return records
        .map((r) => _challengeFromRecord(
              r,
              me,
              byChallenge[r.id] ?? const [],
              const [],
            ))
        .whereType<Challenge>()
        .toList(growable: false);
  }

  Future<Challenge> getDetail(String challengeId) async {
    final me = _requireUserId();
    final record = await _pb
        .collection('challenges')
        .getOne(challengeId, expand: 'proposerId,opponentId');

    final objectiveRecords = await _pb
        .collection('challenge_objectives')
        .getFullList(
          filter: 'challengeId = "$challengeId"',
          sort: 'sortOrder',
        );
    final objectives = objectiveRecords
        .map(_objectiveFromRecord)
        .toList(growable: false);

    final completionRecords = await _pb
        .collection('challenge_completions')
        .getFullList(filter: 'challengeId = "$challengeId"');
    final completions = completionRecords
        .map(_completionFromRecord)
        .toList(growable: false);

    final challenge = _challengeFromRecord(record, me, objectives, completions);
    if (challenge == null) {
      throw StateError('Challenge $challengeId missing expanded user data');
    }
    return challenge;
  }

  Future<Challenge> create({
    required String opponentId,
    required String penaltyObjective,
    required List<NewChallengeObjectiveDraft> objectives,
  }) async {
    final me = _requireUserId();
    final challenge = await _pb.collection('challenges').create(
      body: {
        'proposerId': me,
        'opponentId': opponentId,
        'status': 'proposed',
        'penaltyObjective': penaltyObjective,
        'isTie': false,
        'penaltyApplied': false,
      },
      expand: 'proposerId,opponentId',
    );

    try {
      for (var i = 0; i < objectives.length; i++) {
        final draft = objectives[i];
        await _pb.collection('challenge_objectives').create(body: {
          'challengeId': challenge.id,
          'title': draft.title,
          'description': draft.description,
          'sortOrder': i,
        });
      }
    } catch (_) {
      // Rollback the parent challenge so we don't leave a half-built proposal.
      // Cancelling rather than deleting preserves the audit trail; the
      // updateRule allows the proposer to flip status while still 'proposed'.
      try {
        await _pb
            .collection('challenges')
            .update(challenge.id, body: {'status': 'cancelled'});
      } catch (_) {}
      rethrow;
    }

    return getDetail(challenge.id);
  }

  Future<Challenge> accept(String challengeId) async {
    final monday = _mondayOfThisWeekUtc();
    final sunday = monday.add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1));

    await _pb.collection('challenges').update(challengeId, body: {
      'status': 'active',
      'weekStart': monday.toIso8601String(),
      'weekEnd': sunday.toIso8601String(),
    });
    return getDetail(challengeId);
  }

  Future<void> reject(String challengeId) async {
    await _pb
        .collection('challenges')
        .update(challengeId, body: {'status': 'rejected'});
  }

  Future<Challenge> cancel(String challengeId) async {
    await _pb
        .collection('challenges')
        .update(challengeId, body: {'status': 'cancelled'});
    return getDetail(challengeId);
  }

  /// Transitions an active challenge to `completed`. Idempotent at the data
  /// layer — if another client raced and already closed it, the resulting PB
  /// 403 (status no longer 'active') is rethrown so callers can swallow it.
  Future<Challenge> closeChallenge({
    required String challengeId,
    required String? winnerId,
    required String? loserId,
    required bool isTie,
  }) async {
    await _pb.collection('challenges').update(challengeId, body: {
      'status': 'completed',
      'winnerId': winnerId ?? '',
      'loserId': loserId ?? '',
      'isTie': isTie,
    });
    return getDetail(challengeId);
  }

  /// Sets `penaltyApplied=true` on a completed challenge. Allowed by the
  /// updateRule only for the loser.
  Future<Challenge> markPenaltyApplied(String challengeId) async {
    await _pb
        .collection('challenges')
        .update(challengeId, body: {'penaltyApplied': true});
    return getDetail(challengeId);
  }

  Future<ChallengeCompletion> markCompletion({
    required String challengeId,
    required String objectiveId,
    required DateTime date,
    required bool completed,
  }) async {
    final me = _requireUserId();
    final dayUtc = DateTime.utc(date.year, date.month, date.day);
    final dayIso = dayUtc.toIso8601String();

    // PB stores dates as `YYYY-MM-DD HH:MM:SS.fffZ` (space separator) but
    // the SDK serializes Dart DateTimes as ISO with `T`. Filtering with
    // either `=` or string range on the date field doesn't reliably match
    // across that format gap, so skip the date filter and pick the row
    // matching `dayUtc` in Dart — at most one per (user, objective, day).
    final existing = await _pb.collection('challenge_completions').getList(
          page: 1,
          perPage: 50,
          filter:
              'challengeId = "$challengeId" && userId = "$me" && objectiveId = "$objectiveId"',
        );

    final match = existing.items.where((r) {
      final raw = r.getStringValue('date');
      final parsed = DateTime.tryParse(raw)?.toUtc();
      if (parsed == null) return false;
      return parsed.year == dayUtc.year &&
          parsed.month == dayUtc.month &&
          parsed.day == dayUtc.day;
    }).toList();

    final RecordModel record;
    if (match.isEmpty) {
      record = await _pb.collection('challenge_completions').create(body: {
        'challengeId': challengeId,
        'userId': me,
        'objectiveId': objectiveId,
        'date': dayIso,
        'completed': completed,
      });
    } else {
      record = await _pb
          .collection('challenge_completions')
          .update(match.first.id, body: {'completed': completed});
    }
    return _completionFromRecord(record);
  }

  // ---- mappers ----

  Challenge? _challengeFromRecord(
    RecordModel record,
    String myId,
    List<ChallengeObjective> objectives,
    List<ChallengeCompletion> completions,
  ) {
    final proposerId = record.getStringValue('proposerId');
    final iAmProposer = proposerId == myId;
    final otherKey = iAmProposer ? 'opponentId' : 'proposerId';
    final expanded = record.expand[otherKey];
    if (expanded == null || expanded.isEmpty) return null;
    final other = expanded.first;

    return Challenge(
      id: record.id,
      status: ChallengeStatus.fromString(record.getStringValue('status')),
      opponent: Friend(
        id: other.id,
        username: other.getStringValue('username'),
        displayName: other.getStringValue('displayName'),
        avatarEmoji: other.getStringValue('avatarEmoji'),
      ),
      iAmProposer: iAmProposer,
      penaltyObjective: record.getStringValue('penaltyObjective'),
      objectives: objectives,
      completions: completions,
      weekStart: _parseDateOrNull(record.getStringValue('weekStart')),
      weekEnd: _parseDateOrNull(record.getStringValue('weekEnd')),
      winnerId: _emptyToNull(record.getStringValue('winnerId')),
      loserId: _emptyToNull(record.getStringValue('loserId')),
      isTie: record.getBoolValue('isTie'),
      penaltyApplied: record.getBoolValue('penaltyApplied'),
      createdAt: _parseDateOrNull(record.getStringValue('created')) ??
          DateTime.now(),
    );
  }

  ChallengeObjective _objectiveFromRecord(RecordModel record) {
    return ChallengeObjective(
      id: record.id,
      title: record.getStringValue('title'),
      description: record.getStringValue('description'),
      sortOrder: record.getIntValue('sortOrder'),
    );
  }

  ChallengeCompletion _completionFromRecord(RecordModel record) {
    final dateRaw = record.getStringValue('date');
    return ChallengeCompletion(
      id: record.id,
      userId: record.getStringValue('userId'),
      objectiveId: record.getStringValue('objectiveId'),
      date: _parseDateOrNull(dateRaw) ?? DateTime.now(),
      completed: record.getBoolValue('completed'),
    );
  }

  static DateTime? _parseDateOrNull(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String? _emptyToNull(String raw) => raw.isEmpty ? null : raw;

  static DateTime _mondayOfThisWeekUtc() {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }
}
