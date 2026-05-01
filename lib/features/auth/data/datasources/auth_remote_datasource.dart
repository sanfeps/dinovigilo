import 'dart:async';

import 'package:pocketbase/pocketbase.dart';

import 'package:dinovigilo/features/auth/data/datasources/auth_secure_storage.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_user.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource._(this._pb);

  final PocketBase _pb;

  static Future<AuthRemoteDatasource> create({
    required String baseUrl,
    required AuthSecureStorage storage,
  }) async {
    final initial = await storage.read();
    final authStore = AsyncAuthStore(
      save: storage.write,
      clear: storage.clear,
      initial: initial,
    );
    final pb = PocketBase(baseUrl, authStore: authStore);
    return AuthRemoteDatasource._(pb);
  }

  PocketBase get client => _pb;

  AuthSession? get currentSession => _readSession();

  Stream<AuthSession?> watchSession() async* {
    yield _readSession();
    yield* _pb.authStore.onChange.map((_) => _readSession());
  }

  Future<AuthSession> signIn({
    required String identity,
    required String password,
  }) async {
    final result = await _pb
        .collection('users')
        .authWithPassword(identity, password);
    return _sessionFromAuth(result);
  }

  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    required String avatarEmoji,
  }) async {
    await _pb.collection('users').create(body: {
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'username': username,
      'displayName': displayName,
      'avatarEmoji': avatarEmoji,
    });
    return signIn(identity: email, password: password);
  }

  Future<void> signOut() async {
    _pb.authStore.clear();
  }

  Future<AuthSession?> refresh() async {
    if (!_pb.authStore.isValid) return null;
    final result = await _pb.collection('users').authRefresh();
    return _sessionFromAuth(result);
  }

  AuthSession? _readSession() {
    if (!_pb.authStore.isValid) return null;
    final model = _pb.authStore.model;
    if (model is! RecordModel) return null;
    return AuthSession(
      token: _pb.authStore.token,
      user: _userFromRecord(model),
    );
  }

  AuthSession _sessionFromAuth(RecordAuth auth) => AuthSession(
        token: auth.token,
        user: _userFromRecord(auth.record!),
      );

  AuthUser _userFromRecord(RecordModel record) => AuthUser(
        id: record.id,
        email: record.getStringValue('email'),
        username: record.getStringValue('username'),
        displayName: record.getStringValue('displayName'),
        avatarEmoji: record.getStringValue('avatarEmoji'),
        optInScreenTime: record.getBoolValue('optInScreenTime'),
      );
}
