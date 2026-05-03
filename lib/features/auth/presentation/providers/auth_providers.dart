import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/constants/api_constants.dart';
import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dinovigilo/features/auth/data/datasources/auth_secure_storage.dart';
import 'package:dinovigilo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';
import 'package:dinovigilo/features/auth/domain/repositories/auth_repository.dart';
import 'package:dinovigilo/features/auth/domain/usecases/sign_in.dart';
import 'package:dinovigilo/features/auth/domain/usecases/sign_out.dart';
import 'package:dinovigilo/features/auth/domain/usecases/sign_up.dart';
import 'package:dinovigilo/features/auth/domain/usecases/update_avatar.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthSecureStorage authSecureStorage(AuthSecureStorageRef ref) {
  return AuthSecureStorage(
    const FlutterSecureStorage(),
    ApiConstants.secureStorageAuthKey,
  );
}

@Riverpod(keepAlive: true)
Future<AuthRemoteDatasource> authRemoteDatasource(
  AuthRemoteDatasourceRef ref,
) async {
  final storage = ref.watch(authSecureStorageProvider);
  return AuthRemoteDatasource.create(
    baseUrl: ApiConstants.pocketBaseUrl,
    storage: storage,
  );
}

@Riverpod(keepAlive: true)
Future<AuthRepository> authRepository(AuthRepositoryRef ref) async {
  final remote = await ref.watch(authRemoteDatasourceProvider.future);
  final analytics = ref.watch(analyticsServiceProvider);
  return AuthRepositoryImpl(remote, analytics);
}

@Riverpod(keepAlive: true)
Stream<AuthSession?> authSession(AuthSessionRef ref) async* {
  final repo = await ref.watch(authRepositoryProvider.future);
  yield* repo.watchSession();
}

@riverpod
Future<SignInUseCase> signInUseCase(SignInUseCaseRef ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return SignInUseCase(repo);
}

@riverpod
Future<SignUpUseCase> signUpUseCase(SignUpUseCaseRef ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return SignUpUseCase(repo);
}

@riverpod
Future<SignOutUseCase> signOutUseCase(SignOutUseCaseRef ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return SignOutUseCase(repo);
}

@riverpod
Future<UpdateAvatarUseCase> updateAvatarUseCase(
  UpdateAvatarUseCaseRef ref,
) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return UpdateAvatarUseCase(repo);
}
