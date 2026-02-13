import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:dinovigilo/features/dinosaurs/domain/entities/pending_egg.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class EggCard extends StatelessWidget {
  final PendingEgg egg;

  const EggCard({super.key, required this.egg});

  @override
  Widget build(BuildContext context) {
    final rarityColor = egg.rarity.color;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: rarityColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: rarityColor.withValues(alpha: 0.2),
                  radius: 22,
                  child: egg.isPaused
                      ? const Text(
                          '\u{1F95A}',
                          style: TextStyle(fontSize: 22),
                        )
                      : const Text(
                          '\u{1F95A}',
                          style: TextStyle(fontSize: 22),
                        )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .rotate(
                            begin: -0.03,
                            end: 0.03,
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            egg.rarity.displayName,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: rarityColor,
                            ),
                          ),
                          if (egg.isPaused) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                context.l10n.paused,
                                style:
                                    context.textTheme.labelSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.daysProgress(
                          egg.daysIncubated,
                          egg.totalDaysNeeded,
                        ),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${egg.daysRemaining}',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rarityColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'left',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: egg.progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: rarityColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    egg.isPaused
                        ? Colors.orange.withValues(alpha: 0.5)
                        : rarityColor,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
