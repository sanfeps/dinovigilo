import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class DaySelector extends StatelessWidget {
  final int dayIndex;
  final DateTime date;
  final int objectiveCount;
  final bool isExpanded;
  final VoidCallback onTap;

  const DaySelector({
    super.key,
    required this.dayIndex,
    required this.date,
    required this.objectiveCount,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekdayName = DateFormat.EEEE().format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isExpanded
              ? context.colorScheme.primaryContainer
              : context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExpanded
                ? context.colorScheme.primary
                : context.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: objectiveCount > 0
                    ? context.colorScheme.primary.withValues(alpha: 0.2)
                    : context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${dayIndex + 1}',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: objectiveCount > 0
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dayN(dayIndex + 1),
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    weekdayName,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              context.l10n.objectivesAssigned(objectiveCount),
              style: context.textTheme.bodySmall?.copyWith(
                color: objectiveCount > 0
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
