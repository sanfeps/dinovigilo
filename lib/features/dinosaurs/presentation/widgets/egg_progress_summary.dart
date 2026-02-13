import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:dinovigilo/features/dinosaurs/domain/entities/pending_egg.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class EggProgressSummary extends StatelessWidget {
  final List<PendingEgg> eggs;
  final VoidCallback? onTap;

  const EggProgressSummary({
    super.key,
    required this.eggs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (eggs.isEmpty) return const SizedBox.shrink();

    final displayEggs = eggs.take(3).toList();
    final remaining = eggs.length - displayEggs.length;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ...displayEggs.indexed.map((entry) {
                final (index, egg) = entry;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CircleAvatar(
                    backgroundColor:
                        egg.rarity.color.withValues(alpha: 0.2),
                    radius: 16,
                    child: const Text(
                      '\u{1F95A}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      delay: (index * 100).ms,
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    );
              }),
              if (remaining > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '+$remaining',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  context.l10n.eggsIncubating(eggs.length),
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(
          begin: -0.1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}
