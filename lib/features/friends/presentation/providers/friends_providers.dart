import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/auth/presentation/providers/auth_providers.dart';
import 'package:dinovigilo/features/friends/data/datasources/friends_remote_datasource.dart';
import 'package:dinovigilo/features/friends/data/repositories/friends_repository_impl.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';
import 'package:dinovigilo/features/friends/domain/repositories/friends_repository.dart';
import 'package:dinovigilo/features/friends/domain/usecases/accept_friendship.dart';
import 'package:dinovigilo/features/friends/domain/usecases/add_friend_by_code.dart';
import 'package:dinovigilo/features/friends/domain/usecases/get_friendships.dart';
import 'package:dinovigilo/features/friends/domain/usecases/get_my_invite_code.dart';
import 'package:dinovigilo/features/friends/domain/usecases/reject_friendship.dart';

part 'friends_providers.g.dart';

@Riverpod(keepAlive: true)
Future<FriendsRemoteDatasource> friendsRemoteDatasource(
  FriendsRemoteDatasourceRef ref,
) async {
  final auth = await ref.watch(authRemoteDatasourceProvider.future);
  return FriendsRemoteDatasource(auth.client);
}

@Riverpod(keepAlive: true)
Future<FriendsRepository> friendsRepository(FriendsRepositoryRef ref) async {
  final remote = await ref.watch(friendsRemoteDatasourceProvider.future);
  final analytics = ref.watch(analyticsServiceProvider);
  return FriendsRepositoryImpl(remote, analytics);
}

@riverpod
Future<GetMyInviteCodeUseCase> getMyInviteCodeUseCase(
  GetMyInviteCodeUseCaseRef ref,
) async {
  final repo = await ref.watch(friendsRepositoryProvider.future);
  return GetMyInviteCodeUseCase(repo);
}

@riverpod
Future<AddFriendByCodeUseCase> addFriendByCodeUseCase(
  AddFriendByCodeUseCaseRef ref,
) async {
  final repo = await ref.watch(friendsRepositoryProvider.future);
  return AddFriendByCodeUseCase(repo);
}

@riverpod
Future<GetFriendshipsUseCase> getFriendshipsUseCase(
  GetFriendshipsUseCaseRef ref,
) async {
  final repo = await ref.watch(friendsRepositoryProvider.future);
  return GetFriendshipsUseCase(repo);
}

@riverpod
Future<AcceptFriendshipUseCase> acceptFriendshipUseCase(
  AcceptFriendshipUseCaseRef ref,
) async {
  final repo = await ref.watch(friendsRepositoryProvider.future);
  return AcceptFriendshipUseCase(repo);
}

@riverpod
Future<RejectFriendshipUseCase> rejectFriendshipUseCase(
  RejectFriendshipUseCaseRef ref,
) async {
  final repo = await ref.watch(friendsRepositoryProvider.future);
  return RejectFriendshipUseCase(repo);
}

/// All friendships involving the current user. Refetch via
/// `ref.invalidate(friendshipsListProvider)` for pull-to-refresh.
@riverpod
Future<List<Friendship>> friendshipsList(FriendshipsListRef ref) async {
  final useCase = await ref.watch(getFriendshipsUseCaseProvider.future);
  final result = await useCase.execute();
  return result.when(
    success: (list) => list,
    failure: (failure) => throw failure,
  );
}

/// Current user's 6-char invite code from `user_private`.
@riverpod
Future<String> myInviteCode(MyInviteCodeRef ref) async {
  final useCase = await ref.watch(getMyInviteCodeUseCaseProvider.future);
  final result = await useCase.execute();
  return result.when(
    success: (code) => code,
    failure: (failure) => throw failure,
  );
}
