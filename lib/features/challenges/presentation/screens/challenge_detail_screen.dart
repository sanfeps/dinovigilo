import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/features/auth/presentation/providers/auth_providers.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/presentation/providers/challenges_providers.dart';
import 'package:dinovigilo/features/challenges/presentation/screens/mark_day_screen.dart';
import 'package:dinovigilo/features/challenges/presentation/widgets/challenge_progress_grid.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(challengeDetailProvider(challengeId));
    // Keep the realtime subscription alive for as long as the screen is
    // mounted. Errors here are non-fatal — the detail still loads from the
    // initial fetch; we just won't see opponent updates live.
    ref.watch(challengeRealtimeProvider(challengeId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.challengeDetailTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              e is Failure ? e.message : e.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (challenge) => _DetailBody(challenge: challenge),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.challenge});
  final Challenge challenge;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _busy = false;

  Future<void> _accept() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final useCase = await ref.read(acceptChallengeUseCaseProvider.future);
      final result = await useCase.execute(widget.challenge.id);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(challengesListProvider);
          ref.invalidate(challengeDetailProvider(widget.challenge.id));
          context.showSnackBar(l.challengeAccepted);
        },
        failure: (failure) =>
            context.showSnackBar(failure.message, isError: true),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final l = context.l10n;
    final ok = await _confirm(l.rejectChallenge, l.rejectChallengeConfirm);
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final useCase = await ref.read(rejectChallengeUseCaseProvider.future);
      final result = await useCase.execute(widget.challenge.id);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(challengesListProvider);
          context.showSnackBar(l.challengeRejected);
          Navigator.of(context).pop();
        },
        failure: (failure) =>
            context.showSnackBar(failure.message, isError: true),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    final ok = await _confirm(l.cancelChallenge, l.cancelChallengeConfirm);
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final useCase = await ref.read(cancelChallengeUseCaseProvider.future);
      final result = await useCase.execute(widget.challenge.id);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(challengesListProvider);
          context.showSnackBar(l.challengeCancelled);
          Navigator.of(context).pop();
        },
        failure: (failure) =>
            context.showSnackBar(failure.message, isError: true),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final l = context.l10n;
    final opponentName = c.opponent.displayName.isEmpty
        ? c.opponent.username
        : c.opponent.displayName;
    final emoji = c.opponent.avatarEmoji.isEmpty ? '🦖' : c.opponent.avatarEmoji;

    final showAcceptReject =
        c.status == ChallengeStatus.proposed && !c.iAmProposer;
    final showCancel =
        c.status == ChallengeStatus.proposed && c.iAmProposer;

    final outcomeBanner = c.status == ChallengeStatus.completed
        ? _OutcomeBanner(challenge: c, opponentName: opponentName)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (outcomeBanner != null) ...[
          outcomeBanner,
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.iAmProposer
                            ? l.youChallenged(opponentName)
                            : l.opponentChallengedYou(opponentName),
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${c.opponent.username}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l.objectivesLabel, style: context.textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < c.objectives.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      '${i + 1}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(c.objectives[i].title),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(l.penaltyLabel, style: context.textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          color: AppColors.warning.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(child: Text(c.penaltyObjective)),
              ],
            ),
          ),
        ),
        if (c.status == ChallengeStatus.active && c.weekEnd != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.weekRange(_format(c.weekStart), _format(c.weekEnd)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (showAcceptReject) ...[
          FilledButton.icon(
            onPressed: _busy ? null : _accept,
            icon: const Icon(Icons.check),
            label: Text(l.acceptChallenge),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _reject,
            icon: const Icon(Icons.close),
            label: Text(l.rejectChallenge),
          ),
        ],
        if (showCancel)
          OutlinedButton.icon(
            onPressed: _busy ? null : _cancel,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            icon: const Icon(Icons.cancel_outlined),
            label: Text(l.cancelChallenge),
          ),
        if (c.status == ChallengeStatus.active) ...[
          const SizedBox(height: 16),
          Builder(
            builder: (innerContext) {
              final me =
                  ref.watch(authSessionProvider).valueOrNull?.user.id;
              if (me == null) return const SizedBox.shrink();
              return ChallengeProgressGrid(
                challenge: c,
                myUserId: me,
                now: DateTime.now(),
                onTapMyToday: () => showMarkDaySheet(
                  innerContext,
                  challenge: c,
                  day: DateTime.now(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => showMarkDaySheet(
                      context,
                      challenge: c,
                      day: DateTime.now(),
                    ),
            icon: const Icon(Icons.checklist_rtl),
            label: Text(l.markToday),
          ),
        ],
      ],
    );
  }

  static String _format(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }
}

class _OutcomeBanner extends StatelessWidget {
  const _OutcomeBanner({
    required this.challenge,
    required this.opponentName,
  });

  final Challenge challenge;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (emoji, color, title, subtitle) = _styleFor(l);

    return Card(
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, String, String) _styleFor(dynamic l) {
    if (challenge.isTie) {
      return (
        '🤝',
        AppColors.info,
        l.outcomeTieTitle as String,
        l.outcomeTieSubtitle as String,
      );
    }
    // Two players, so I won iff the winner isn't the opponent.
    final iWon = challenge.winnerId != null &&
        challenge.winnerId != challenge.opponent.id;
    if (iWon) {
      return (
        '🏆',
        AppColors.success,
        l.outcomeWonTitle as String,
        l.outcomeWonSubtitle(opponentName) as String,
      );
    }
    return (
      '💀',
      AppColors.error,
      l.outcomeLostTitle as String,
      l.outcomeLostSubtitle(opponentName) as String,
    );
  }
}
