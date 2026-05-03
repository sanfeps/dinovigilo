import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/presentation/providers/challenges_providers.dart';
import 'package:dinovigilo/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:dinovigilo/features/challenges/presentation/screens/create_challenge_screen.dart';
import 'package:dinovigilo/features/challenges/presentation/screens/trophy_room_screen.dart';
import 'package:dinovigilo/features/challenges/presentation/widgets/challenge_tile.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesListProvider);

    Future<void> refresh() async {
      ref.invalidate(challengesListProvider);
      await ref
          .read(challengesListProvider.future)
          .catchError((_) => <Challenge>[]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.challenges),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: context.l10n.trophyRoomTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TrophyRoomScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreateChallengeScreen(),
            ),
          );
          if (created == true) {
            ref.invalidate(challengesListProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newChallenge),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: challengesAsync.when(
          loading: () => const Center(child: LoadingIndicator()),
          error: (e, _) => _ErrorBox(
            message: e is Failure ? e.message : e.toString(),
            onRetry: refresh,
          ),
          data: (challenges) => _ChallengesList(challenges: challenges),
        ),
      ),
    );
  }
}

class _ChallengesList extends ConsumerWidget {
  const _ChallengesList({required this.challenges});
  final List<Challenge> challenges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = challenges
        .where((c) => c.status == ChallengeStatus.proposed && !c.iAmProposer)
        .toList(growable: false);
    final active = challenges
        .where((c) => c.status == ChallengeStatus.active)
        .toList(growable: false);
    final outgoing = challenges
        .where((c) => c.status == ChallengeStatus.proposed && c.iAmProposer)
        .toList(growable: false);
    // Completed challenges live in the Trophy Room; only show "dead" proposals
    // here (rejected/cancelled) so the inline history stays useful.
    final history = challenges
        .where((c) =>
            c.status == ChallengeStatus.rejected ||
            c.status == ChallengeStatus.cancelled)
        .toList(growable: false);

    if (challenges.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 64),
          _EmptyState(message: context.l10n.noChallengesYet),
        ],
      );
    }

    void open(Challenge c) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChallengeDetailScreen(challengeId: c.id),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (incoming.isNotEmpty) ...[
          _SectionHeader(
            title: context.l10n.incomingChallenges,
            count: incoming.length,
          ),
          const SizedBox(height: 8),
          ...incoming.map((c) => ChallengeTile(challenge: c, onTap: () => open(c))),
          const SizedBox(height: 16),
        ],
        if (active.isNotEmpty) ...[
          _SectionHeader(
            title: context.l10n.activeChallenges,
            count: active.length,
          ),
          const SizedBox(height: 8),
          ...active.map((c) => ChallengeTile(challenge: c, onTap: () => open(c))),
          const SizedBox(height: 16),
        ],
        if (outgoing.isNotEmpty) ...[
          _SectionHeader(
            title: context.l10n.sentChallenges,
            count: outgoing.length,
          ),
          const SizedBox(height: 8),
          ...outgoing.map((c) => ChallengeTile(challenge: c, onTap: () => open(c))),
          const SizedBox(height: 16),
        ],
        if (history.isNotEmpty) ...[
          _SectionHeader(
            title: context.l10n.challengeHistory,
            count: history.length,
          ),
          const SizedBox(height: 8),
          ...history.map((c) => ChallengeTile(challenge: c, onTap: () => open(c))),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
