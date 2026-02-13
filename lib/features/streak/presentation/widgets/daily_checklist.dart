import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class DailyChecklist extends StatefulWidget {
  final List<DailyCompletion> completions;
  final List<Objective> objectives;
  final void Function(String completionId, bool completed) onToggle;

  const DailyChecklist({
    super.key,
    required this.completions,
    required this.objectives,
    required this.onToggle,
  });

  @override
  State<DailyChecklist> createState() => _DailyChecklistState();
}

class _DailyChecklistState extends State<DailyChecklist>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _bounceControllers = {};

  @override
  void dispose() {
    for (final controller in _bounceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AnimationController _getOrCreateController(String id) {
    return _bounceControllers.putIfAbsent(id, () {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });
  }

  void _handleToggle(String completionId, bool value) {
    HapticFeedback.mediumImpact();
    if (value) {
      _getOrCreateController(completionId).forward(from: 0);
    }
    widget.onToggle(completionId, value);
  }

  @override
  Widget build(BuildContext context) {
    final objectiveMap = {for (final o in widget.objectives) o.id: o};
    final completedCount =
        widget.completions.where((c) => c.completed).length;
    final total = widget.completions.length;
    final progress = total == 0 ? 0.0 : completedCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.objectivesCompleted(completedCount),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: progress, end: progress),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(
              completedCount == total
                  ? AppColors.success
                  : context.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...widget.completions.map((completion) {
          final objective = objectiveMap[completion.objectiveId];
          if (objective == null) return const SizedBox.shrink();

          final controller = _getOrCreateController(completion.id);
          final bounceAnimation = Tween<double>(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.elasticOut))
              .animate(controller);

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: completion.completed
                    ? AppColors.success.withValues(alpha: 0.08)
                    : Colors.transparent,
              ),
              child: Card(
                color: completion.completed
                    ? AppColors.success.withValues(alpha: 0.05)
                    : null,
                child: CheckboxListTile(
                  value: completion.completed,
                  onChanged: (value) {
                    _handleToggle(completion.id, value ?? false);
                  },
                  title: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: (context.textTheme.bodyLarge ?? const TextStyle())
                        .copyWith(
                      decoration: completion.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: completion.completed
                          ? context.colorScheme.onSurfaceVariant
                          : context.textTheme.bodyLarge?.color,
                    ),
                    child: Text(objective.title),
                  ),
                  subtitle: objective.description != null &&
                          objective.description!.isNotEmpty
                      ? Text(
                          objective.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  secondary: ScaleTransition(
                    scale: bounceAnimation,
                    child: Icon(
                      completion.completed
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: completion.completed
                          ? AppColors.success
                          : context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
