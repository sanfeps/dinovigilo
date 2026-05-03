import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/presentation/providers/challenges_providers.dart';
import 'package:dinovigilo/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class TrophyRoomScreen extends ConsumerWidget {
  const TrophyRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(challengesListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trophyRoomTitle)),
      body: async.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is Failure ? e.message : e.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (all) {
          final finished = all
              .where((c) => c.status == ChallengeStatus.completed)
              .toList(growable: false)
            ..sort((a, b) => _orderKey(b).compareTo(_orderKey(a)));

          if (finished.isEmpty) {
            return _EmptyTrophyRoom();
          }

          final stats = _TrophyStats.from(finished);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _StatsCard(stats: stats),
              const SizedBox(height: 16),
              ..._buildGrouped(context, finished),
            ],
          );
        },
      ),
    );
  }

  static DateTime _orderKey(Challenge c) => c.weekEnd ?? c.createdAt;

  static List<Widget> _buildGrouped(
    BuildContext context,
    List<Challenge> sorted,
  ) {
    final monthFormatter = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    );
    final widgets = <Widget>[];
    String? currentLabel;

    for (final c in sorted) {
      final label = monthFormatter.format(_orderKey(c));
      if (label != currentLabel) {
        if (currentLabel != null) widgets.add(const SizedBox(height: 16));
        widgets.add(_MonthHeader(label: label));
        widgets.add(const SizedBox(height: 8));
        currentLabel = label;
      }
      widgets.add(_TrophyTile(challenge: c));
    }
    return widgets;
  }
}

class _TrophyStats {
  const _TrophyStats({
    required this.wins,
    required this.losses,
    required this.ties,
    required this.currentWinStreak,
  });

  final int wins;
  final int losses;
  final int ties;
  final int currentWinStreak;

  int get total => wins + losses + ties;

  /// 0-100 (rounded). Returns 0 when no decided challenges yet.
  int get winRate => total == 0 ? 0 : ((wins * 100) / total).round();

  /// Walks the most-recent-first list and counts the leading run of wins.
  /// Stops at the first non-win (loss or tie).
  factory _TrophyStats.from(List<Challenge> sortedDesc) {
    var wins = 0;
    var losses = 0;
    var ties = 0;
    var streak = 0;
    var streakOpen = true;

    for (final c in sortedDesc) {
      final outcome = _outcomeFor(c);
      switch (outcome) {
        case _Outcome.won:
          wins++;
          if (streakOpen) streak++;
        case _Outcome.lost:
          losses++;
          streakOpen = false;
        case _Outcome.tie:
          ties++;
          streakOpen = false;
        case _Outcome.unknown:
          // No declared winner and not a tie — don't count toward stats but
          // also don't break the streak (treat as ignorable).
          break;
      }
    }

    return _TrophyStats(
      wins: wins,
      losses: losses,
      ties: ties,
      currentWinStreak: streak,
    );
  }
}

enum _Outcome { won, lost, tie, unknown }

_Outcome _outcomeFor(Challenge c) {
  if (c.isTie) return _Outcome.tie;
  if (c.winnerId == null) return _Outcome.unknown;
  return c.winnerId == c.opponent.id ? _Outcome.lost : _Outcome.won;
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final _TrophyStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatTile(
                  label: l.trophyStatsWins,
                  value: '${stats.wins}',
                  color: AppColors.success,
                ),
                _StatTile(
                  label: l.trophyStatsLosses,
                  value: '${stats.losses}',
                  color: AppColors.error,
                ),
                _StatTile(
                  label: l.trophyStatsTies,
                  value: '${stats.ties}',
                  color: AppColors.info,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatTile(
                  label: l.trophyStatsWinRate,
                  value: '${stats.winRate}%',
                  color: AppColors.accent,
                ),
                _StatTile(
                  label: l.trophyStatsCurrentStreak,
                  value: stats.currentWinStreak == 0
                      ? '—'
                      : l.trophyStreakSuffix(stats.currentWinStreak),
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        label,
        style: context.textTheme.titleSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrophyTile extends StatelessWidget {
  const _TrophyTile({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final outcome = _outcomeFor(challenge);
    final (icon, color) = switch (outcome) {
      _Outcome.won => ('🏆', AppColors.success),
      _Outcome.lost => ('💀', AppColors.error),
      _Outcome.tie => ('🤝', AppColors.info),
      _Outcome.unknown => ('⚔️', AppColors.textTertiary),
    };

    final opponent = challenge.opponent;
    final name = opponent.displayName.isEmpty
        ? opponent.username
        : opponent.displayName;
    final range = _weekRange(context, challenge);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChallengeDetailScreen(challengeId: challenge.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 22)),
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
                    const SizedBox(height: 2),
                    Text(
                      range,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  String _weekRange(BuildContext context, Challenge c) {
    final start = c.weekStart;
    final end = c.weekEnd;
    if (start == null || end == null) {
      return DateFormat.yMMMd(
        Localizations.localeOf(context).toString(),
      ).format(c.createdAt);
    }
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).toString());
    return context.l10n.trophyWeekRange(
      fmt.format(start.toLocal()),
      fmt.format(end.toLocal()),
    );
  }
}

class _EmptyTrophyRoom extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              context.l10n.trophyRoomEmpty,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
