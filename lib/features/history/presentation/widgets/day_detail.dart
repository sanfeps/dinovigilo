import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class DayDetail extends StatelessWidget {
  final DateTime date;
  final List<DailyCompletion> completions;
  final List<Objective> objectives;

  const DayDetail({
    super.key,
    required this.date,
    required this.completions,
    required this.objectives,
  });

  @override
  Widget build(BuildContext context) {
    final objectiveMap = {for (final o in objectives) o.id: o};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMEd().format(date),
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (completions.isEmpty)
              Text(
                context.l10n.noDataForDay,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              ...completions.map((c) {
                final objective = objectiveMap[c.objectiveId];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        c.completed
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        color: c.completed
                            ? AppColors.success
                            : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          objective?.title ?? c.objectiveId,
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
