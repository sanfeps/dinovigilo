import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/dinosaurs/presentation/providers/egg_providers.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/widgets/egg_progress_summary.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/streak/presentation/providers/streak_providers.dart';
import 'package:dinovigilo/features/streak/presentation/widgets/daily_checklist.dart';
import 'package:dinovigilo/features/streak/presentation/widgets/perfect_day_banner.dart';
import 'package:dinovigilo/features/streak/presentation/widgets/streak_status_card.dart';
import 'package:dinovigilo/features/streak/presentation/widgets/yesterday_buffer_card.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/widgets/empty_state.dart';
import 'package:dinovigilo/shared/widgets/error_display.dart';
import 'package:dinovigilo/features/settings/presentation/screens/settings_screen.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class TodayScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToIncubator;

  const TodayScreen({super.key, this.onNavigateToIncubator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakStatusStreamProvider);
    final todayObjectivesAsync = ref.watch(todayObjectivesProvider);
    final showBuffer = ref.watch(yesterdayBufferAvailableProvider);

    // Trigger day-end processing on startup
    ref.watch(processDayEndOnStartupProvider);

    // Watch initialization so it stays alive and completes
    final initAsync = ref.watch(initializeTodayCompletionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.today),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: todayObjectivesAsync.when(
        data: (objectives) {
          if (objectives.isEmpty) {
            // No today objectives, but still show buffer if available
            if (showBuffer) {
              return const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: YesterdayBufferCard(),
              );
            }
            return EmptyState(
              message: context.l10n.noActiveSprint,
              icon: Icons.today_outlined,
            );
          }

          // Wait for initialization to complete before showing completions
          return initAsync.when(
            data: (_) =>
                _buildBody(context, ref, objectives, streakAsync, showBuffer),
            loading: () => const LoadingIndicator(),
            error: (error, _) => ErrorDisplay(
              message: error.toString(),
              onRetry: () =>
                  ref.invalidate(initializeTodayCompletionsProvider),
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(todayObjectivesProvider),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<Objective> objectives,
    AsyncValue streakAsync,
    bool showBuffer,
  ) {
    final completionsAsync = ref.watch(todayCompletionsStreamProvider);
    final eggsAsync = ref.watch(pendingEggsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBuffer) ...[
            const YesterdayBufferCard(),
            const SizedBox(height: 8),
          ],
          streakAsync.when(
            data: (status) => StreakStatusCard(status: status),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          eggsAsync.whenOrNull(
                data: (eggs) => EggProgressSummary(
                  eggs: eggs,
                  onTap: onNavigateToIncubator,
                ),
              ) ??
              const SizedBox.shrink(),
          const SizedBox(height: 8),
          completionsAsync.when(
            data: (completions) {
              final allDone = completions.isNotEmpty &&
                  completions.every((c) => c.completed);
              return Column(
                children: [
                  if (allDone)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: PerfectDayBanner(),
                    ),
                  DailyChecklist(
                    completions: completions,
                    objectives: objectives,
                    onToggle: (completionId, completed) =>
                        _handleToggle(context, ref, completionId, completed),
                  ),
                ],
              );
            },
            loading: () => const LoadingIndicator(),
            error: (error, _) => ErrorDisplay(
              message: error.toString(),
              onRetry: () =>
                  ref.invalidate(todayCompletionsStreamProvider),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
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
}
