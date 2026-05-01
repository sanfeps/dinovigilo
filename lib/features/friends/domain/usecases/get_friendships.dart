import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';
import 'package:dinovigilo/features/friends/domain/repositories/friends_repository.dart';

class GetFriendshipsUseCase {
  const GetFriendshipsUseCase(this._repository);
  final FriendsRepository _repository;

  Future<Result<List<Friendship>>> execute() => _repository.getFriendships();
}
