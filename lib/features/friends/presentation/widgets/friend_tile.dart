import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';
import 'package:dinovigilo/features/friends/presentation/providers/friends_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class FriendTile extends ConsumerStatefulWidget {
  const FriendTile({
    super.key,
    required this.friendship,
    required this.onChanged,
  });

  final Friendship friendship;
  final VoidCallback onChanged;

  @override
  ConsumerState<FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends ConsumerState<FriendTile> {
  bool _busy = false;

  Future<void> _confirmRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removeFriend),
        content: Text(
          context.l10n.removeFriendConfirmation(
            widget.friendship.friend.displayName.isEmpty
                ? widget.friendship.friend.username
                : widget.friendship.friend.displayName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _remove();
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      final useCase =
          await ref.read(rejectFriendshipUseCaseProvider.future);
      final result = await useCase.execute(widget.friendship.id);
      if (!mounted) return;
      result.when(
        success: (_) {
          context.showSnackBar(context.l10n.friendRemoved);
          widget.onChanged();
        },
        failure: (f) => context.showSnackBar(
          f is NetworkFailure ? context.l10n.errorNetwork : f.message,
          isError: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friendship.friend;
    final isOutgoingPending =
        widget.friendship.status == FriendshipStatus.pending &&
            !widget.friendship.isIncoming;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceVariant,
          child: Text(
            friend.avatarEmoji.isEmpty ? '🦖' : friend.avatarEmoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          friend.displayName.isEmpty ? friend.username : friend.displayName,
        ),
        subtitle: Text(
          isOutgoingPending
              ? '@${friend.username} • ${context.l10n.waitingForResponse}'
              : '@${friend.username}',
          style: isOutgoingPending
              ? const TextStyle(color: AppColors.textTertiary)
              : null,
        ),
        trailing: _busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _confirmRemove,
              ),
      ),
    );
  }
}
