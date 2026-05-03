import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';
import 'package:dinovigilo/features/auth/domain/repositories/auth_repository.dart';

class UpdateAvatarUseCase {
  const UpdateAvatarUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AuthSession>> execute(String emoji) =>
      _repository.updateAvatar(emoji);
}
