import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';
import 'package:dinovigilo/features/friends/presentation/providers/friends_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class PendingInvitationTile extends ConsumerStatefulWidget {
  const PendingInvitationTile({
    super.key,
    required this.friendship,
    required this.onChanged,
  });

  final Friendship friendship;
  final VoidCallback onChanged;

  @override
  ConsumerState<PendingInvitationTile> createState() =>
      _PendingInvitationTileState();
}

class _PendingInvitationTileState
    extends ConsumerState<PendingInvitationTile> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      final useCase =
          await ref.read(acceptFriendshipUseCaseProvider.future);
      final result = await useCase.execute(widget.friendship.id);
      if (!mounted) return;
      result.when(
        success: (_) {
          context.showSnackBar(context.l10n.friendshipAccepted);
          widget.onChanged();
        },
        failure: (f) =>
            context.showSnackBar(_msg(f), isError: true),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
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
        failure: (f) =>
            context.showSnackBar(_msg(f), isError: true),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _msg(Failure f) => switch (f) {
        NetworkFailure() => context.l10n.errorNetwork,
        _ => f.message,
      };

  @override
  Widget build(BuildContext context) {
    final friend = widget.friendship.friend;
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
        subtitle: Text('@${friend.username}'),
        trailing: _busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error),
                    tooltip: context.l10n.reject,
                    onPressed: _reject,
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.success),
                    tooltip: context.l10n.accept,
                    onPressed: _accept,
                  ),
                ],
              ),
      ),
    );
  }
}
