import 'package:pocketbase/pocketbase.dart';

import 'package:dinovigilo/features/friends/domain/entities/friend.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';

/// Thrown when no auth model is present — caller maps it to an AuthFailure.
class NotSignedInException implements Exception {
  const NotSignedInException();
}

class FriendsRemoteDatasource {
  FriendsRemoteDatasource(this._pb);

  final PocketBase _pb;

  String _requireUserId() {
    final model = _pb.authStore.model;
    if (model is RecordModel) return model.id;
    throw const NotSignedInException();
  }

  Future<String> getMyInviteCode() async {
    final me = _requireUserId();
    final record = await _pb
        .collection('user_private')
        .getFirstListItem('userId="$me"');
    return record.getStringValue('inviteCode');
  }

  Future<Friendship> addByCode(String code) async {
    final me = _requireUserId();
    final response = await _pb.send(
      '/api/friends/by-code',
      method: 'POST',
      body: {'code': code.trim().toUpperCase()},
    );
    final data = response as Map<String, dynamic>;
    final f = data['friendship'] as Map<String, dynamic>;
    final friendJson = data['friend'] as Map<String, dynamic>;

    return Friendship(
      id: f['id'] as String,
      friend: Friend(
        id: friendJson['id'] as String,
        username: (friendJson['username'] ?? '') as String,
        displayName: (friendJson['displayName'] ?? '') as String,
        avatarEmoji: (friendJson['avatarEmoji'] ?? '') as String,
      ),
      status: FriendshipStatus.fromString(f['status'] as String),
      isIncoming: f['userB'] == me,
      createdAt: DateTime.now(),
    );
  }

  Future<List<Friendship>> getFriendships() async {
    final me = _requireUserId();
    final records = await _pb.collection('friendships').getFullList(
          filter: 'userA = "$me" || userB = "$me"',
          expand: 'userA,userB',
          sort: '-created',
        );

    return records
        .map((r) => _friendshipFromRecord(r, me))
        .whereType<Friendship>()
        .toList(growable: false);
  }

  Future<Friendship> accept(String friendshipId) async {
    final me = _requireUserId();
    final updated = await _pb.collection('friendships').update(
      friendshipId,
      body: {
        'status': 'accepted',
        'acceptedAt': DateTime.now().toUtc().toIso8601String(),
      },
      expand: 'userA,userB',
    );
    final mapped = _friendshipFromRecord(updated, me);
    if (mapped == null) {
      throw StateError('Friendship $friendshipId missing expanded user data');
    }
    return mapped;
  }

  Future<void> reject(String friendshipId) async {
    await _pb.collection('friendships').delete(friendshipId);
  }

  Friendship? _friendshipFromRecord(RecordModel record, String myId) {
    final userAId = record.getStringValue('userA');
    final iAmA = userAId == myId;

    final expanded = record.expand[iAmA ? 'userB' : 'userA'];
    if (expanded == null || expanded.isEmpty) return null;
    final otherUser = expanded.first;

    final acceptedAtRaw = record.getStringValue('acceptedAt');
    final createdRaw = record.getStringValue('created');

    return Friendship(
      id: record.id,
      friend: Friend(
        id: otherUser.id,
        username: otherUser.getStringValue('username'),
        displayName: otherUser.getStringValue('displayName'),
        avatarEmoji: otherUser.getStringValue('avatarEmoji'),
      ),
      status: FriendshipStatus.fromString(record.getStringValue('status')),
      isIncoming: !iAmA,
      acceptedAt: acceptedAtRaw.isEmpty ? null : DateTime.tryParse(acceptedAtRaw),
      createdAt: DateTime.tryParse(createdRaw) ?? DateTime.now(),
    );
  }
}

