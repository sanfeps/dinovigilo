import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/auth/presentation/providers/auth_providers.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/services/challenge_progress.dart';
import 'package:dinovigilo/features/challenges/presentation/providers/challenges_providers.dart';
import 'package:dinovigilo/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

/// Renders one card per active challenge directly on the Today tab so the
/// user can mark today's objectives without leaving the screen. Each card's
/// header taps into the full ChallengeDetailScreen.
class TodayChallengesSection extends ConsumerWidget {
  const TodayChallengesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(challengesListProvider);
    return listAsync.maybeWhen(
      data: (list) {
        final active =
            list.where((c) => c.status == ChallengeStatus.active).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            for (final c in active) ...[
              _ChallengeCard(challengeId: c.id),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ChallengeCard extends ConsumerStatefulWidget {
  const _ChallengeCard({required this.challengeId});
  final String challengeId;

  @override
  ConsumerState<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends ConsumerState<_ChallengeCard> {
  /// Optimistic per-objective overrides while a toggle is in flight. Once
  /// the provider returns canonical state the entry is removed.
  final Map<String, bool> _override = <String, bool>{};
  final Set<String> _busy = <String>{};

  Future<void> _toggle({
    required Challenge challenge,
    required String objectiveId,
    required bool nextValue,
  }) async {
    final l = context.l10n;
    setState(() {
      _override[objectiveId] = nextValue;
      _busy.add(objectiveId);
    });
    try {
      final useCase = await ref.read(markCompletionUseCaseProvider.future);
      final result = await useCase.execute(
        challengeId: challenge.id,
        objectiveId: objectiveId,
        date: DateTime.now(),
        completed: nextValue,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(challengeDetailProvider(challenge.id));
          ref.invalidate(challengesListProvider);
          setState(() => _override.remove(objectiveId));
        },
        failure: (failure) {
          setState(() => _override.remove(objectiveId));
          context.showSnackBar(
            failure.message.isEmpty ? l.errorSavingMark : failure.message,
            isError: true,
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _override.remove(objectiveId));
      context.showSnackBar(l.errorSavingMark, isError: true);
    } finally {
      if (mounted) setState(() => _busy.remove(objectiveId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final detailAsync = ref.watch(challengeDetailProvider(widget.challengeId));
    // Hold the realtime subscription alive while the card is on screen.
    ref.watch(challengeRealtimeProvider(widget.challengeId));

    return detailAsync.maybeWhen(
      data: (challenge) {
        if (challenge.status != ChallengeStatus.active) {
          return const SizedBox.shrink();
        }
        final me = ref.watch(authSessionProvider).valueOrNull?.user.id;
        if (me == null) return const SizedBox.shrink();

        final marked = ChallengeProgress.markedObjectiveIdsFor(
          challenge: challenge,
          userId: me,
          day: DateTime.now(),
        );
        final opponentName = challenge.opponent.displayName.isEmpty
            ? challenge.opponent.username
            : challenge.opponent.displayName;
        final emoji = challenge.opponent.avatarEmoji.isEmpty
            ? '🦖'
            : challenge.opponent.avatarEmoji;

        return Card(
          color: AppColors.primary.withValues(alpha: 0.08),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChallengeDetailScreen(
                        challengeId: challenge.id,
                      ),
                    ),
                  );
                },
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.activeChallengeWith(opponentName),
                          style: context.textTheme.titleSmall,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              for (int i = 0; i < challenge.objectives.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                Builder(builder: (_) {
                  final id = challenge.objectives[i].id;
                  final checked = _override[id] ?? marked.contains(id);
                  return _ObjectiveTile(
                    title: challenge.objectives[i].title,
                    checked: checked,
                    busy: _busy.contains(id),
                    onTap: () => _toggle(
                      challenge: challenge,
                      objectiveId: id,
                      nextValue: !checked,
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ObjectiveTile extends StatelessWidget {
  const _ObjectiveTile({
    required this.title,
    required this.checked,
    required this.busy,
    required this.onTap,
  });

  final String title;
  final bool checked;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Checkbox(
                      value: checked,
                      onChanged: (_) => onTap(),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
      ),
    );
  }
}
