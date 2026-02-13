import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class MonthCalendar extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, List<DailyCompletion>> completions;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthCalendar({
    super.key,
    required this.month,
    required this.completions,
    this.selectedDay,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday = 1, offset so Monday is column 0
    final startWeekday = (firstDay.weekday - 1) % 7;

    final dayLabels = [
      context.l10n.mon,
      context.l10n.tue,
      context.l10n.wed,
      context.l10n.thu,
      context.l10n.fri,
      context.l10n.sat,
      context.l10n.sun,
    ];

    return Column(
      children: [
        // Month header with navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousMonth,
            ),
            Text(
              DateFormat.yMMMM().format(month),
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: month.year < now.year ||
                      (month.year == now.year && month.month < now.month)
                  ? onNextMonth
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Day of week headers
        Row(
          children: dayLabels
              .map((label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return const SizedBox.shrink();
            }

            final dayNum = index - startWeekday + 1;
            final date = DateTime(month.year, month.month, dayNum);
            final isFuture = date.isAfter(today);
            final isToday = date == today;
            final isSelected = selectedDay != null &&
                date.year == selectedDay!.year &&
                date.month == selectedDay!.month &&
                date.day == selectedDay!.day;

            final dayCompletions = completions[date];
            final cellColor = _getCellColor(dayCompletions, isFuture);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isFuture
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onDaySelected(date);
                      },
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : isToday
                            ? Border.all(
                                color: AppColors.textSecondary, width: 1.5)
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isFuture
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        fontWeight:
                            isToday || isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getCellColor(List<DailyCompletion>? dayCompletions, bool isFuture) {
    if (isFuture) return Colors.transparent;
    if (dayCompletions == null || dayCompletions.isEmpty) {
      return AppColors.surfaceVariant.withValues(alpha: 0.3);
    }
    final allDone = dayCompletions.every((c) => c.completed);
    if (allDone) {
      return AppColors.success.withValues(alpha: 0.25);
    }
    return AppColors.error.withValues(alpha: 0.2);
  }
}
