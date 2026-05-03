import 'package:pocketbase/pocketbase.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/services/analytics_service.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/challenges/data/datasources/challenges_remote_datasource.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge_completion.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';
import 'package:dinovigilo/features/friends/data/datasources/friends_remote_datasource.dart';

class ChallengesRepositoryImpl implements ChallengesRepository {
  ChallengesRepositoryImpl(this._remote, this._analytics);

  final ChallengesRemoteDatasource _remote;
  final AnalyticsService _analytics;

  @override
  Future<Result<List<Challenge>>> list() => _guard(() async {
        final challenges = await _remote.list();
        return Result.success(challenges);
      });

  @override
  Future<Result<Challenge>> getDetail(String challengeId) => _guard(() async {
        final challenge = await _remote.getDetail(challengeId);
        return Result.success(challenge);
      });

  @override
  Future<Result<Challenge>> create({
    required String opponentId,
    required String penaltyObjective,
    required List<NewChallengeObjectiveDraft> objectives,
  }) =>
      _guard(() async {
        final challenge = await _remote.create(
          opponentId: opponentId,
          penaltyObjective: penaltyObjective,
          objectives: objectives,
        );
        _analytics.logEvent('challenge_created', {
          'challengeId': challenge.id,
          'objectiveCount': objectives.length,
        });
        return Result.success(challenge);
      });

  @override
  Future<Result<Challenge>> accept(String challengeId) => _guard(() async {
        final challenge = await _remote.accept(challengeId);
        _analytics.logEvent('challenge_accepted', {'challengeId': challengeId});
        return Result.success(challenge);
      });

  @override
  Future<Result<void>> reject(String challengeId) => _guard(() async {
        await _remote.reject(challengeId);
        _analytics.logEvent('challenge_rejected', {'challengeId': challengeId});
        return Result.success(null);
      });

  @override
  Future<Result<Challenge>> cancel(String challengeId) => _guard(() async {
        final challenge = await _remote.cancel(challengeId);
        _analytics.logEvent('challenge_cancelled', {'challengeId': challengeId});
        return Result.success(challenge);
      });

  @override
  Future<Result<ChallengeCompletion>> markCompletion({
    required String challengeId,
    required String objectiveId,
    required DateTime date,
    required bool completed,
  }) =>
      _guard(() async {
        final completion = await _remote.markCompletion(
          challengeId: challengeId,
          objectiveId: objectiveId,
          date: date,
          completed: completed,
        );
        return Result.success(completion);
      });

  @override
  Future<Result<Challenge>> closeChallenge({
    required String challengeId,
    required String? winnerId,
    required String? loserId,
    required bool isTie,
  }) =>
      _guard(() async {
        final challenge = await _remote.closeChallenge(
          challengeId: challengeId,
          winnerId: winnerId,
          loserId: loserId,
          isTie: isTie,
        );
        _analytics.logEvent('challenge_closed', {
          'challengeId': challengeId,
          'isTie': isTie,
        });
        return Result.success(challenge);
      });

  @override
  Future<Result<Challenge>> markPenaltyApplied(String challengeId) =>
      _guard(() async {
        final challenge = await _remote.markPenaltyApplied(challengeId);
        _analytics.logEvent('challenge_penalty_applied', {
          'challengeId': challengeId,
        });
        return Result.success(challenge);
      });

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on NotSignedInException {
      return Result.failure(const AuthFailure('Not signed in'));
    } on ClientException catch (e) {
      return Result.failure(_mapClientException(e));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Failure _mapClientException(ClientException e) {
    final code = e.statusCode;
    final raw = e.response['message'] ?? e.toString();
    final message = raw is String ? raw : raw.toString();
    if (code == 0) return NetworkFailure(message);
    if (code == 400) return ValidationFailure(message);
    if (code == 401 || code == 403) return AuthFailure(message);
    if (code == 404) return NotFoundFailure(message);
    return DataFailure(message);
  }
}
