import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';
import 'package:dinovigilo/features/friends/domain/repositories/friends_repository.dart';

class AcceptFriendshipUseCase {
  const AcceptFriendshipUseCase(this._repository);
  final FriendsRepository _repository;

  Future<Result<Friendship>> execute(String friendshipId) =>
      _repository.accept(friendshipId);
}
