import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  /// Emits the current session, or null when logged out. Fires immediately
  /// with the cached state on subscribe and again on every change.
  Stream<AuthSession?> watchSession();

  /// Returns the active session synchronously (null when logged out).
  AuthSession? get currentSession;

  Future<Result<AuthSession>> signIn({
    required String identity,
    required String password,
  });

  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String avatarEmoji,
  });

  Future<Result<void>> signOut();

  /// Hits the backend to refresh the cached user record (e.g., after a
  /// profile change). Returns null if no session is active.
  Future<Result<AuthSession?>> refresh();
}
