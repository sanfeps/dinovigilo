import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:dinovigilo/features/friends/domain/entities/friend.dart';

part 'friendship.freezed.dart';
part 'friendship.g.dart';

enum FriendshipStatus {
  pending,
  accepted,
  blocked;

  static FriendshipStatus fromString(String raw) {
    return switch (raw) {
      'pending' => FriendshipStatus.pending,
      'accepted' => FriendshipStatus.accepted,
      'blocked' => FriendshipStatus.blocked,
      _ => FriendshipStatus.pending,
    };
  }
}

@freezed
class Friendship with _$Friendship {
  const factory Friendship({
    required String id,
    required Friend friend,
    required FriendshipStatus status,

    /// True when status is `pending` AND I am the addressee (userB). Drives
    /// whether to render Accept/Reject controls. For accepted friendships
    /// the value is informational only.
    required bool isIncoming,
    DateTime? acceptedAt,
    required DateTime createdAt,
  }) = _Friendship;

  factory Friendship.fromJson(Map<String, dynamic> json) =>
      _$FriendshipFromJson(json);
}
