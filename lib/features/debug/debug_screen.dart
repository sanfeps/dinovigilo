import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/pending_egg.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/providers/egg_providers.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:dinovigilo/features/streak/presentation/providers/streak_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakStatusStreamProvider);
    final eggsAsync = ref.watch(pendingEggsStreamProvider);
    final dinosAsync = ref.watch(dinosaursStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Streak Status ---
            _SectionHeader('Streak Status'),
            streakAsync.when(
              data: (status) => _StreakStatusCard(status: status),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 8),

            // --- Streak Manipulation ---
            _SectionHeader('Streak Controls'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DebugButton(
                  label: 'Set 29 Days',
                  onTap: () => _setStreak(ref, totalPerfect: 29, streak: 29),
                ),
                _DebugButton(
                  label: 'Set 30 Days',
                  onTap: () => _setStreak(ref, totalPerfect: 30, streak: 30),
                ),
                _DebugButton(
                  label: 'Set 60 Days',
                  onTap: () => _setStreak(ref, totalPerfect: 60, streak: 60),
                ),
                _DebugButton(
                  label: 'Streak +10',
                  onTap: () => _adjustStreak(ref, 10),
                ),
                _DebugButton(
                  label: 'Streak +50',
                  onTap: () => _adjustStreak(ref, 50),
                ),
                _DebugButton(
                  label: 'Break Streak',
                  color: Colors.red,
                  onTap: () => _breakStreak(ref),
                ),
                _DebugButton(
                  label: 'Complete Recovery',
                  color: Colors.green,
                  onTap: () => _completeRecovery(ref),
                ),
                _DebugButton(
                  label: 'Reset All',
                  color: Colors.orange,
                  onTap: () => _resetAll(ref),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Egg Operations ---
            _SectionHeader('Egg Operations'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DebugButton(
                  label: 'Check Egg Creation',
                  color: Colors.teal,
                  onTap: () => _checkEggCreation(context, ref),
                ),
                _DebugButton(
                  label: 'Advance Eggs +1',
                  color: Colors.teal,
                  onTap: () => _advanceEggs(context, ref),
                ),
                _DebugButton(
                  label: 'Check Egg Hatching',
                  color: Colors.teal,
                  onTap: () => _checkEggHatching(context, ref),
                ),
                _DebugButton(
                  label: 'Pause All Eggs',
                  onTap: () => _pauseEggs(context, ref),
                ),
                _DebugButton(
                  label: 'Resume All Eggs',
                  onTap: () => _resumeEggs(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Pending Eggs ---
            _SectionHeader('Pending Eggs'),
            eggsAsync.when(
              data: (eggs) => eggs.isEmpty
                  ? const Text('No pending eggs')
                  : Column(
                      children: eggs.map((e) => _EggCard(egg: e)).toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // --- Collection ---
            _SectionHeader('Hatched Dinosaurs'),
            dinosAsync.when(
              data: (dinos) => dinos.isEmpty
                  ? const Text('No dinosaurs yet')
                  : Column(
                      children:
                          dinos.map((d) => _DinosaurCard(dinosaur: d)).toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // --- Notifications ---
            _SectionHeader('Notifications'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DebugButton(
                  label: 'Egg Created',
                  color: Colors.purple,
                  onTap: () => ref
                      .read(notificationServiceProvider)
                      .showEggCreatedNotification(30),
                ),
                _DebugButton(
                  label: 'Egg Hatched',
                  color: Colors.purple,
                  onTap: () => ref
                      .read(notificationServiceProvider)
                      .showEggHatchedNotification(
                        Dinosaur(
                          id: 'test',
                          speciesId: 'test',
                          hatchedAt: DateTime.now(),
                          streakDayWhenHatched: 60,
                        ),
                      ),
                ),
                _DebugButton(
                  label: 'Recovery Progress',
                  color: Colors.purple,
                  onTap: () => ref
                      .read(notificationServiceProvider)
                      .showRecoveryProgressNotification(2),
                ),
                _DebugButton(
                  label: 'Recovery Complete',
                  color: Colors.purple,
                  onTap: () => ref
                      .read(notificationServiceProvider)
                      .showRecoveryCompleteNotification(),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _setStreak(
    WidgetRef ref, {
    int? totalPerfect,
    int? streak,
  }) async {
    final repo = ref.read(streakRepositoryProvider);
    final result = await repo.getStreakStatus();
    if (result.isFailure) return;
    final current = result.data;
    await repo.updateStreakStatus(current.copyWith(
      totalPerfectDays: totalPerfect ?? current.totalPerfectDays,
      currentStreak: streak ?? current.currentStreak,
      longestStreak: (streak ?? current.currentStreak) > current.longestStreak
          ? (streak ?? current.currentStreak)
          : current.longestStreak,
      isActive: true,
      recoveryDaysNeeded: 0,
    ));
  }

  Future<void> _adjustStreak(WidgetRef ref, int amount) async {
    final repo = ref.read(streakRepositoryProvider);
    final result = await repo.getStreakStatus();
    if (result.isFailure) return;
    final current = result.data;
    final newStreak = current.currentStreak + amount;
    await repo.updateStreakStatus(current.copyWith(
      currentStreak: newStreak,
      longestStreak:
          newStreak > current.longestStreak ? newStreak : current.longestStreak,
      isActive: true,
      recoveryDaysNeeded: 0,
    ));
  }

  Future<void> _breakStreak(WidgetRef ref) async {
    final repo = ref.read(streakRepositoryProvider);
    final result = await repo.getStreakStatus();
    if (result.isFailure) return;
    await repo.updateStreakStatus(result.data.copyWith(
      isActive: false,
      currentStreak: 0,
      recoveryDaysNeeded: 3,
    ));
  }

  Future<void> _completeRecovery(WidgetRef ref) async {
    final repo = ref.read(streakRepositoryProvider);
    final result = await repo.getStreakStatus();
    if (result.isFailure) return;
    await repo.updateStreakStatus(result.data.copyWith(
      isActive: true,
      recoveryDaysNeeded: 0,
    ));
  }

  Future<void> _resetAll(WidgetRef ref) async {
    final repo = ref.read(streakRepositoryProvider);
    await repo.updateStreakStatus(const StreakStatus(
      currentStreak: 0,
      totalPerfectDays: 0,
      longestStreak: 0,
      isActive: true,
      recoveryDaysNeeded: 0,
    ));
  }

  Future<void> _checkEggCreation(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(streakRepositoryProvider);
    final statusResult = await repo.getStreakStatus();
    if (statusResult.isFailure) return;

    final useCase = ref.read(checkEggCreationUseCaseProvider);
    final result = await useCase.execute(statusResult.data);

    if (!context.mounted) return;
    result.when(
      success: (egg) {
        if (egg != null) {
          context.showSnackBar('Egg created! Rarity: ${egg.rarity.name}');
        } else {
          context.showSnackBar(
            'No egg (totalPerfectDays=${statusResult.data.totalPerfectDays}, '
            'need multiple of 30)',
          );
        }
      },
      failure: (e) => context.showSnackBar(e.message, isError: true),
    );
  }

  Future<void> _advanceEggs(BuildContext context, WidgetRef ref) async {
    final useCase = ref.read(advanceEggsUseCaseProvider);
    await useCase.execute();
    if (!context.mounted) return;
    context.showSnackBar('Advanced all non-paused eggs by 1 day');
  }

  Future<void> _checkEggHatching(BuildContext context, WidgetRef ref) async {
    final useCase = ref.read(checkEggHatchingUseCaseProvider);
    final result = await useCase.execute();

    if (!context.mounted) return;
    result.when(
      success: (hatched) {
        if (hatched.isNotEmpty) {
          context.showSnackBar('Hatched ${hatched.length} dinosaur(s)!');
        } else {
          context.showSnackBar('No eggs ready to hatch');
        }
      },
      failure: (e) => context.showSnackBar(e.message, isError: true),
    );
  }

  Future<void> _pauseEggs(BuildContext context, WidgetRef ref) async {
    final useCase = ref.read(pauseAllEggsUseCaseProvider);
    await useCase.execute();
    if (!context.mounted) return;
    context.showSnackBar('All eggs paused');
  }

  Future<void> _resumeEggs(BuildContext context, WidgetRef ref) async {
    final useCase = ref.read(resumeAllEggsUseCaseProvider);
    await useCase.execute();
    if (!context.mounted) return;
    context.showSnackBar('All eggs resumed');
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colorScheme.primary,
        ),
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DebugButton({
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: color != null
          ? FilledButton.styleFrom(
              backgroundColor: color!.withValues(alpha: 0.2),
              foregroundColor: color,
            )
          : null,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _StreakStatusCard extends StatelessWidget {
  final StreakStatus status;
  const _StreakStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Current Streak', '${status.currentStreak}'),
            _row('Total Perfect Days', '${status.totalPerfectDays}'),
            _row('Longest Streak', '${status.longestStreak}'),
            _row('Active', '${status.isActive}'),
            _row('Recovery Days Needed', '${status.recoveryDaysNeeded}'),
            _row('Last Perfect Day',
                status.lastPerfectDay?.toString() ?? 'none'),
            _row('In Recovery', '${status.isInRecoveryMode}'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EggCard extends StatelessWidget {
  final PendingEgg egg;
  const _EggCard({required this.egg});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: egg.rarity.color.withValues(alpha: 0.3),
          child: const Text('🥚'),
        ),
        title: Text('${egg.rarity.name.toUpperCase()} egg'),
        subtitle: Text(
          '${egg.daysIncubated}/${egg.totalDaysNeeded} days '
          '(${egg.daysRemaining} left) '
          '${egg.isPaused ? "PAUSED" : "active"}',
        ),
        dense: true,
      ),
    );
  }
}

class _DinosaurCard extends StatelessWidget {
  final Dinosaur dinosaur;
  const _DinosaurCard({required this.dinosaur});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Text('🦕')),
        title: Text('Species: ${dinosaur.speciesId}'),
        subtitle: Text(
          'Hatched: ${DateFormat.yMd().format(dinosaur.hatchedAt)} '
          '(${dinosaur.streakDayWhenHatched} days incubation)',
        ),
        dense: true,
      ),
    );
  }
}
