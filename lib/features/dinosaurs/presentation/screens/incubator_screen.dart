import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/dinosaurs/presentation/providers/egg_providers.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/widgets/egg_card.dart';
import 'package:dinovigilo/features/streak/presentation/providers/streak_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';
import 'package:dinovigilo/shared/widgets/empty_state.dart';
import 'package:dinovigilo/shared/widgets/error_display.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class IncubatorScreen extends ConsumerWidget {
  const IncubatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggsAsync = ref.watch(pendingEggsStreamProvider);
    final streakAsync = ref.watch(streakStatusStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.incubator),
      ),
      body: eggsAsync.when(
        data: (eggs) {
          if (eggs.isEmpty) {
            return EmptyState(
              message: context.l10n.noEggsYet,
              icon: Icons.egg_outlined,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Recovery banner
              streakAsync.whenOrNull(
                    data: (status) {
                      if (!status.isInRecoveryMode) return null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pause_circle_filled,
                                  color: AppColors.warning,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.recoveryMode,
                                        style: context.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.l10n.recoveryProgress(
                                          status.recoveryDaysNeeded,
                                        ),
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ) ??
                  const SizedBox.shrink(),
              // Egg cards
              ...eggs.map((egg) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: EggCard(egg: egg),
                  )),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(pendingEggsStreamProvider),
        ),
      ),
    );
  }
}
