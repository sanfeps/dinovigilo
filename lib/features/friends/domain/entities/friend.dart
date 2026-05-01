import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend.freezed.dart';
part 'friend.g.dart';

/// Public-only view of another user — never includes email or inviteCode.
@freezed
class Friend with _$Friend {
  const factory Friend({
    required String id,
    required String username,
    required String displayName,
    required String avatarEmoji,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
}
