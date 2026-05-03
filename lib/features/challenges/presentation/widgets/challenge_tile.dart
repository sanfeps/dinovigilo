import 'package:flutter/material.dart';

import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/l10n/app_localizations.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class ChallengeTile extends StatelessWidget {
  const ChallengeTile({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opponent = challenge.opponent;
    final name = opponent.displayName.isEmpty
        ? opponent.username
        : opponent.displayName;
    final emoji = opponent.avatarEmoji.isEmpty ? '🦖' : opponent.avatarEmoji;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(context),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(challenge: challenge),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final l = context.l10n;
    final count = challenge.objectives.length;
    final base = count == 1
        ? l.objectiveCountSingular
        : l.objectiveCountPlural(count);
    if (challenge.status == ChallengeStatus.active &&
        challenge.weekEnd != null) {
      return '$base · ${l.endsOn(_formatDay(challenge.weekEnd!))}';
    }
    return base;
  }

  static String _formatDay(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _styleFor(context, challenge);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color) _styleFor(BuildContext context, Challenge c) {
    final l = context.l10n;
    return switch (c.status) {
      ChallengeStatus.proposed when c.iAmProposer =>
        (l.statusWaiting, AppColors.warning),
      ChallengeStatus.proposed => (l.statusInvited, AppColors.info),
      ChallengeStatus.active => (l.statusActive, AppColors.success),
      ChallengeStatus.completed => _completedStyle(l, c),
      ChallengeStatus.rejected => (l.statusRejected, AppColors.textTertiary),
      ChallengeStatus.cancelled => (l.statusCancelled, AppColors.textTertiary),
    };
  }

  static (String, Color) _completedStyle(AppLocalizations l, Challenge c) {
    if (c.isTie) return (l.statusTie, AppColors.info);
    if (c.winnerId == null) {
      return (l.statusCompleted, AppColors.textSecondary);
    }
    // Two players, so I won iff the winner isn't the opponent.
    final iWon = c.winnerId != c.opponent.id;
    return iWon
        ? (l.statusWon, AppColors.success)
        : (l.statusLost, AppColors.error);
  }
}
