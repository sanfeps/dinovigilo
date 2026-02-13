import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/dinosaurs/presentation/providers/egg_providers.dart';
import 'package:dinovigilo/features/history/domain/entities/objective_stats.dart';
import 'package:dinovigilo/features/history/presentation/providers/history_providers.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/presentation/providers/objective_providers.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:dinovigilo/features/streak/presentation/providers/streak_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class StatsSection extends ConsumerWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakStatusStreamProvider);
    final dinosAsync = ref.watch(dinosaursStreamProvider);
    final statsAsync = ref.watch(objectiveStatsProvider);
    final objectivesAsync = ref.watch(objectivesStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.statistics,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Top-level stats row
        streakAsync.when(
          data: (status) => _buildStreakStats(context, status, dinosAsync),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        // Per-objective completion rates
        statsAsync.when(
          data: (stats) => objectivesAsync.when(
            data: (objectives) =>
                _buildObjectiveStats(context, stats, objectives),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStreakStats(
    BuildContext context,
    StreakStatus status,
    AsyncValue dinosAsync,
  ) {
    final dinoCount = dinosAsync.whenOrNull(data: (d) => d.length) ?? 0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatCard(
          label: context.l10n.currentStreak,
          value: '${status.currentStreak}',
          color: AppColors.primary,
        ),
        _StatCard(
          label: context.l10n.longestStreak,
          value: '${status.longestStreak}',
          color: AppColors.accent,
        ),
        _StatCard(
          label: context.l10n.totalPerfectDays,
          value: '${status.totalPerfectDays}',
          color: AppColors.success,
        ),
        _StatCard(
          label: context.l10n.totalDinosaurs,
          value: '$dinoCount',
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildObjectiveStats(
    BuildContext context,
    List<ObjectiveStats> stats,
    List<Objective> objectives,
  ) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final objectiveMap = {for (final o in objectives) o.id: o};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.completionRate,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...stats.map((stat) {
          final objective = objectiveMap[stat.objectiveId];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        objective?.title ?? stat.objectiveId,
                        style: context.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(stat.completionRate * 100).round()}%',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stat.completionRate,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor:
                        AlwaysStoppedAnimation(_rateColor(stat.completionRate)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 0.8) return AppColors.success;
    if (rate >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 48) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
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
          ),
        ),
      ),
    );
  }
}
