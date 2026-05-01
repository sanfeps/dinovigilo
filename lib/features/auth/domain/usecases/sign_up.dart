import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';
import 'package:dinovigilo/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AuthSession>> execute({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String avatarEmoji = '🦖',
  }) =>
      _repository.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
      );
}
