import 'package:flutter/material.dart';

import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class ObjectiveAssignment extends StatelessWidget {
  final int dayIndex;
  final List<Objective> allObjectives;
  final Set<String> selectedObjectiveIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onApplyToAll;
  final VoidCallback? onCopyFromPrevious;
  final VoidCallback onClear;

  const ObjectiveAssignment({
    super.key,
    required this.dayIndex,
    required this.allObjectives,
    required this.selectedObjectiveIds,
    required this.onToggle,
    required this.onApplyToAll,
    this.onCopyFromPrevious,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectObjectivesForDay,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...allObjectives.map((objective) {
            final isSelected = selectedObjectiveIds.contains(objective.id);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (_) => onToggle(objective.id),
              title: Text(
                objective.title,
                style: context.textTheme.bodyMedium,
              ),
              subtitle: objective.description != null
                  ? Text(
                      objective.description!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
          const Divider(),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text(context.l10n.applyToAllDays),
                onPressed: onApplyToAll,
                avatar: const Icon(Icons.select_all, size: 16),
              ),
              if (onCopyFromPrevious != null)
                ActionChip(
                  label: Text(context.l10n.copyFromPreviousDay),
                  onPressed: onCopyFromPrevious,
                  avatar: const Icon(Icons.content_copy, size: 16),
                ),
              ActionChip(
                label: Text(context.l10n.clearDay),
                onPressed: onClear,
                avatar: const Icon(Icons.clear_all, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
