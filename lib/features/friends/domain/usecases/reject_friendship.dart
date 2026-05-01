import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/friends/domain/repositories/friends_repository.dart';

class RejectFriendshipUseCase {
  const RejectFriendshipUseCase(this._repository);
  final FriendsRepository _repository;

  Future<Result<void>> execute(String friendshipId) =>
      _repository.reject(friendshipId);
}
