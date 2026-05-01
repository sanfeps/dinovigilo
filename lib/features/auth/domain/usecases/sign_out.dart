import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> execute() => _repository.signOut();
}
