import 'package:pocketbase/pocketbase.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/services/analytics_service.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';
import 'package:dinovigilo/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._analytics);

  final AuthRemoteDatasource _remote;
  final AnalyticsService _analytics;

  @override
  AuthSession? get currentSession => _remote.currentSession;

  @override
  Stream<AuthSession?> watchSession() => _remote.watchSession();

  @override
  Future<Result<AuthSession>> signIn({
    required String identity,
    required String password,
  }) async {
    try {
      final session = await _remote.signIn(
        identity: identity,
        password: password,
      );
      _analytics.logEvent('auth_sign_in', {'userId': session.user.id});
      return Result.success(session);
    } on ClientException catch (e) {
      return Result.failure(_mapClientException(e));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String avatarEmoji = '🦖',
  }) async {
    try {
      final session = await _remote.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
      );
      _analytics.logEvent('auth_sign_up', {'userId': session.user.id});
      return Result.success(session);
    } on ClientException catch (e) {
      return Result.failure(_mapClientException(e));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remote.signOut();
      _analytics.logEvent('auth_sign_out', {});
      return Result.success(null);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthSession?>> refresh() async {
    try {
      final session = await _remote.refresh();
      return Result.success(session);
    } on ClientException catch (e) {
      // 401: token expired/invalid → treat as logged out
      if (e.statusCode == 401) {
        await _remote.signOut();
        return Result.success(null);
      }
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
    if (code == 400) return ValidationFailure(_extractFieldErrors(e) ?? message);
    if (code == 401 || code == 403) return AuthFailure(message);
    if (code == 404) return NotFoundFailure(message);
    return DataFailure(message);
  }

  String? _extractFieldErrors(ClientException e) {
    final data = e.response['data'];
    if (data is! Map || data.isEmpty) return null;
    final parts = <String>[];
    data.forEach((field, info) {
      if (info is Map && info['message'] is String) {
        parts.add('$field: ${info['message']}');
      }
    });
    return parts.isEmpty ? null : parts.join(', ');
  }
}
