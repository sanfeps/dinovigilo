import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';
import 'package:dinovigilo/features/friends/presentation/providers/friends_providers.dart';
import 'package:dinovigilo/features/friends/presentation/widgets/add_by_code_form.dart';
import 'package:dinovigilo/features/friends/presentation/widgets/friend_tile.dart';
import 'package:dinovigilo/features/friends/presentation/widgets/invite_code_card.dart';
import 'package:dinovigilo/features/friends/presentation/widgets/pending_invitation_tile.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteCodeAsync = ref.watch(myInviteCodeProvider);
    final friendshipsAsync = ref.watch(friendshipsListProvider);

    Future<void> refresh() async {
      ref.invalidate(myInviteCodeProvider);
      ref.invalidate(friendshipsListProvider);
      await Future.wait([
        ref.read(myInviteCodeProvider.future).catchError((_) => ''),
        ref
            .read(friendshipsListProvider.future)
            .catchError((_) => <Friendship>[]),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.friends),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InviteCodeCard(asyncCode: inviteCodeAsync),
            const SizedBox(height: 16),
            AddByCodeForm(
              onSuccess: () => ref.invalidate(friendshipsListProvider),
            ),
            const SizedBox(height: 24),
            _FriendshipsSections(asyncFriendships: friendshipsAsync),
          ],
        ),
      ),
    );
  }
}

class _FriendshipsSections extends ConsumerWidget {
  const _FriendshipsSections({required this.asyncFriendships});

  final AsyncValue<List<Friendship>> asyncFriendships;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncFriendships.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: LoadingIndicator(),
      ),
      error: (e, _) => _ErrorBox(
        message: e is Failure ? e.message : e.toString(),
        onRetry: () => ref.invalidate(friendshipsListProvider),
      ),
      data: (friendships) {
        final incoming = friendships
            .where((f) =>
                f.status == FriendshipStatus.pending && f.isIncoming)
            .toList(growable: false);
        final outgoing = friendships
            .where((f) =>
                f.status == FriendshipStatus.pending && !f.isIncoming)
            .toList(growable: false);
        final accepted = friendships
            .where((f) => f.status == FriendshipStatus.accepted)
            .toList(growable: false);

        if (friendships.isEmpty) {
          return _EmptyState(message: context.l10n.noFriendsYet);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (incoming.isNotEmpty) ...[
              _SectionHeader(
                title: context.l10n.pendingInvitations,
                count: incoming.length,
              ),
              const SizedBox(height: 8),
              ...incoming.map(
                (f) => PendingInvitationTile(
                  friendship: f,
                  onChanged: () => ref.invalidate(friendshipsListProvider),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (accepted.isNotEmpty) ...[
              _SectionHeader(
                title: context.l10n.friendsList,
                count: accepted.length,
              ),
              const SizedBox(height: 8),
              ...accepted.map(
                (f) => FriendTile(
                  friendship: f,
                  onChanged: () => ref.invalidate(friendshipsListProvider),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (outgoing.isNotEmpty) ...[
              _SectionHeader(
                title: context.l10n.sentInvitations,
                count: outgoing.length,
              ),
              const SizedBox(height: 8),
              ...outgoing.map(
                (f) => FriendTile(
                  friendship: f,
                  onChanged: () => ref.invalidate(friendshipsListProvider),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('🥚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

