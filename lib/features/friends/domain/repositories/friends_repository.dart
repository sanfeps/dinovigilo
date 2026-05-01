import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';

abstract class FriendsRepository {
  /// Reads the current user's invite code from `user_private`.
  Future<Result<String>> getMyInviteCode();

  /// Sends a friend request via `POST /api/friends/by-code`.
  Future<Result<Friendship>> addByCode(String code);

  /// All friendships involving the current user (any status, any direction).
  Future<Result<List<Friendship>>> getFriendships();

  /// Accept an incoming pending invitation. Caller must be `userB`.
  Future<Result<Friendship>> accept(String friendshipId);

  /// Reject (or unfriend) by deleting the row.
  Future<Result<void>> reject(String friendshipId);
}
