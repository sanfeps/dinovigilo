import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/friends/domain/repositories/friends_repository.dart';

class GetMyInviteCodeUseCase {
  const GetMyInviteCodeUseCase(this._repository);
  final FriendsRepository _repository;

  Future<Result<String>> execute() => _repository.getMyInviteCode();
}
