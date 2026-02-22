import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/streak/presentation/providers/streak_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

/// Grace-period card shown when a streak just broke.
/// Lets the user retroactively complete yesterday's objectives
/// to restore the streak before recovery mode locks in.
class YesterdayBufferCard extends ConsumerStatefulWidget {
  const YesterdayBufferCard({super.key});

  @override
  ConsumerState<YesterdayBufferCard> createState() =>
      _YesterdayBufferCardState();
}

class _YesterdayBufferCardState extends ConsumerState<YesterdayBufferCard> {
  bool _restoreCalled = false;

  @override
  Widget build(BuildContext context) {
    final objectivesAsync = ref.watch(yesterdayObjectivesProvider);
    final completionsAsync = ref.watch(yesterdayCompletionsStreamProvider);
    final initAsync = ref.watch(initializeYesterdayCompletionsProvider);

    return Card(
      color: AppColors.warning.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.warning.withValues(alpha: 0.6),
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
                const Icon(
                  Icons.access_time_filled,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Yesterday — Last chance!',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Complete yesterday\'s objectives to restore your streak.',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.warning.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),
            // Wait for initialization before showing items
            initAsync.when(
              data: (_) => completionsAsync.when(
                data: (completions) {
                  if (completions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return objectivesAsync.when(
                    data: (objectives) {
                      final objectiveMap = {
                        for (final o in objectives) o.id: o
                      };
                      final completedCount =
                          completions.where((c) => c.completed).length;
                      final total = completions.length;

                      // Auto-restore once all are completed
                      if (completedCount == total &&
                          total > 0 &&
                          !_restoreCalled) {
                        _restoreCalled = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _doRestore(context);
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$completedCount / $total done',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: completedCount / total,
                              end: completedCount / total,
                            ),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                              value: value,
                              backgroundColor:
                                  AppColors.warning.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...completions.map((completion) {
                            final objective =
                                objectiveMap[completion.objectiveId];
                            if (objective == null) {
                              return const SizedBox.shrink();
                            }
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: completion.completed,
                              activeColor: AppColors.warning,
                              checkColor: Colors.black,
                              onChanged: (value) {
                                HapticFeedback.selectionClick();
                                _toggle(
                                  context,
                                  completion.id,
                                  value ?? false,
                                );
                              },
                              title: Text(
                                objective.title,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  decoration: completion.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: completion.completed
                                      ? context.colorScheme.onSurfaceVariant
                                      : context.textTheme.bodyMedium?.color,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                            );
                          }),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    String completionId,
    bool completed,
  ) async {
    final useCase = ref.read(toggleObjectiveCompletionUseCaseProvider);
    final result = await useCase.execute(
      completionId: completionId,
      completed: completed,
    );

    if (!context.mounted) return;

    result.when(
      success: (_) {},
      failure: (error) => context.showSnackBar(error.message, isError: true),
    );
  }

  Future<void> _doRestore(BuildContext context) async {
    await ref.read(streakBufferRestoreNotifierProvider.notifier).restore();

    if (!context.mounted) return;
    context.showSnackBar('Streak saved! Keep going!');
  }
}
