import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';
import 'package:dinovigilo/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AuthSession>> execute({
    required String identity,
    required String password,
  }) =>
      _repository.signIn(identity: identity, password: password);
}
