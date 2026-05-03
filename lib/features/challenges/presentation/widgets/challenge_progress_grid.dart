import 'package:flutter/material.dart';

import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/services/challenge_progress.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

/// 7×2 day grid with a header row of weekday labels. The first data row is
/// the current user (callable for today), the second is the opponent
/// (read-only). A scoreboard underneath counts failed days per side — lower
/// is better.
class ChallengeProgressGrid extends StatelessWidget {
  const ChallengeProgressGrid({
    super.key,
    required this.challenge,
    required this.myUserId,
    required this.now,
    required this.onTapMyToday,
  });

  final Challenge challenge;
  final String myUserId;
  final DateTime now;

  /// Invoked when the user taps the cell that represents *today* in their
  /// own row. Past/future cells are non-interactive.
  final VoidCallback onTapMyToday;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final opponentId = challenge.opponent.id;

    final myCells = ChallengeProgress.daysFor(
      challenge: challenge,
      userId: myUserId,
      now: now,
    );
    final theirCells = ChallengeProgress.daysFor(
      challenge: challenge,
      userId: opponentId,
      now: now,
    );

    final myFailed = myCells.where((c) => c.status == DayStatus.failed).length;
    final theirFailed =
        theirCells.where((c) => c.status == DayStatus.failed).length;

    final weekdays = [l.mon, l.tue, l.wed, l.thu, l.fri, l.sat, l.sun];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderRow(weekdays: weekdays),
            const SizedBox(height: 8),
            _DayRow(
              label: l.youLabel,
              emoji: '🦖',
              cells: myCells,
              isMe: true,
              onTapMyToday: onTapMyToday,
            ),
            const SizedBox(height: 8),
            _DayRow(
              label: challenge.opponent.displayName.isEmpty
                  ? challenge.opponent.username
                  : challenge.opponent.displayName,
              emoji: challenge.opponent.avatarEmoji.isEmpty
                  ? '🦖'
                  : challenge.opponent.avatarEmoji,
              cells: theirCells,
              isMe: false,
              onTapMyToday: () {},
            ),
            const Divider(height: 24),
            _Scoreboard(myFailed: myFailed, theirFailed: theirFailed),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.weekdays});
  final List<String> weekdays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 72),
        for (final day in weekdays)
          Expanded(
            child: Center(
              child: Text(
                day,
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.emoji,
    required this.cells,
    required this.isMe,
    required this.onTapMyToday,
  });

  final String label;
  final String emoji;
  final List<DayCell> cells;
  final bool isMe;
  final VoidCallback onTapMyToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        for (final cell in cells)
          Expanded(
            child: Center(
              child: _DayCellView(
                status: cell.status,
                tappable: isMe && cell.status == DayStatus.pending,
                onTap: onTapMyToday,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayCellView extends StatelessWidget {
  const _DayCellView({
    required this.status,
    required this.tappable,
    required this.onTap,
  });

  final DayStatus status;
  final bool tappable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(status);
    final box = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: visual.border, width: 1),
      ),
      child: visual.icon == null
          ? null
          : Icon(visual.icon, size: 18, color: visual.iconColor),
    );

    if (!tappable) return box;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: box,
    );
  }

  static _CellVisual _visualFor(DayStatus status) {
    switch (status) {
      case DayStatus.done:
        return _CellVisual(
          background: AppColors.success.withValues(alpha: 0.25),
          border: AppColors.success,
          icon: Icons.check,
          iconColor: AppColors.success,
        );
      case DayStatus.failed:
        return _CellVisual(
          background: AppColors.error.withValues(alpha: 0.2),
          border: AppColors.error,
          icon: Icons.close,
          iconColor: AppColors.error,
        );
      case DayStatus.pending:
        return _CellVisual(
          background: AppColors.warning.withValues(alpha: 0.15),
          border: AppColors.warning,
          icon: null,
          iconColor: AppColors.warning,
        );
      case DayStatus.future:
        return const _CellVisual(
          background: AppColors.surfaceVariant,
          border: AppColors.divider,
          icon: null,
          iconColor: AppColors.textTertiary,
        );
    }
  }
}

class _CellVisual {
  const _CellVisual({
    required this.background,
    required this.border,
    required this.icon,
    required this.iconColor,
  });
  final Color background;
  final Color border;
  final IconData? icon;
  final Color iconColor;
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.myFailed, required this.theirFailed});
  final int myFailed;
  final int theirFailed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Score(label: l.youLabel, failed: myFailed),
        Text(
          '–',
          style: context.textTheme.titleLarge?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        _Score(label: l.opponentLabel, failed: theirFailed),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.failed});
  final String label;
  final int failed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$failed',
          style: context.textTheme.headlineMedium?.copyWith(
            color: failed == 0 ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          context.l10n.failedDayCount(failed),
          style: context.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
