import 'package:pocketbase/pocketbase.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/services/analytics_service.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/friends/data/datasources/friends_remote_datasource.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';
import 'package:dinovigilo/features/friends/domain/repositories/friends_repository.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl(this._remote, this._analytics);

  final FriendsRemoteDatasource _remote;
  final AnalyticsService _analytics;

  @override
  Future<Result<String>> getMyInviteCode() => _guard(() async {
        final code = await _remote.getMyInviteCode();
        return Result.success(code);
      });

  @override
  Future<Result<Friendship>> addByCode(String code) => _guard(() async {
        final friendship = await _remote.addByCode(code);
        _analytics.logEvent('friend_added_by_code', {
          'friendshipId': friendship.id,
        });
        return Result.success(friendship);
      });

  @override
  Future<Result<List<Friendship>>> getFriendships() => _guard(() async {
        final friendships = await _remote.getFriendships();
        return Result.success(friendships);
      });

  @override
  Future<Result<Friendship>> accept(String friendshipId) => _guard(() async {
        final friendship = await _remote.accept(friendshipId);
        _analytics.logEvent('friendship_accepted', {
          'friendshipId': friendshipId,
        });
        return Result.success(friendship);
      });

  @override
  Future<Result<void>> reject(String friendshipId) => _guard(() async {
        await _remote.reject(friendshipId);
        _analytics.logEvent('friendship_rejected', {
          'friendshipId': friendshipId,
        });
        return Result.success(null);
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
