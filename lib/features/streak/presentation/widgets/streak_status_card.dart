import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class StreakStatusCard extends StatelessWidget {
  final StreakStatus status;

  const StreakStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.isInRecoveryMode
                        ? context.l10n.recoveryMode
                        : context.l10n.streakDays(status.currentStreak),
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (status.isInRecoveryMode) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.recoveryProgress(status.recoveryDaysNeeded),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: (3 - status.recoveryDaysNeeded) / 3,
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.warning),
                ),
              ),
            ],
            if (!status.isInRecoveryMode && status.currentStreak > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${status.totalPerfectDays} total',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Best: ${status.longestStreak}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (status.isInRecoveryMode) {
      return const Icon(
        Icons.healing,
        color: AppColors.warning,
        size: 28,
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1500.ms, color: AppColors.warning.withValues(alpha: 0.3));
    }

    final icon = Icon(
      Icons.local_fire_department,
      color: AppColors.primary,
      size: 28,
    );

    if (status.currentStreak > 0) {
      return icon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.15, 1.15),
            duration: 800.ms,
            curve: Curves.easeInOut,
          );
    }

    return icon;
  }
}
