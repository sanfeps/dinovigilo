import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/auth/presentation/providers/auth_providers.dart';
import 'package:dinovigilo/features/challenges/domain/entities/challenge.dart';
import 'package:dinovigilo/features/challenges/domain/services/challenge_progress.dart';
import 'package:dinovigilo/features/challenges/presentation/providers/challenges_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

/// Bottom-sheet modal for the current user to toggle their completions on
/// [day] for [challenge]. Optimistic UI: each toggle flips local state and
/// fires the use case in the background; failures revert and show a snackbar.
Future<void> showMarkDaySheet(
  BuildContext context, {
  required Challenge challenge,
  required DateTime day,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _MarkDaySheet(challenge: challenge, day: day),
  );
}

class _MarkDaySheet extends ConsumerStatefulWidget {
  const _MarkDaySheet({required this.challenge, required this.day});

  final Challenge challenge;
  final DateTime day;

  @override
  ConsumerState<_MarkDaySheet> createState() => _MarkDaySheetState();
}

class _MarkDaySheetState extends ConsumerState<_MarkDaySheet> {
  late Set<String> _marked;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    final me = ref.read(authSessionProvider).valueOrNull?.user.id;
    _marked = me == null
        ? <String>{}
        : ChallengeProgress.markedObjectiveIdsFor(
            challenge: widget.challenge,
            userId: me,
            day: widget.day,
          );
  }

  Future<void> _toggle(String objectiveId) async {
    final l = context.l10n;
    final wasMarked = _marked.contains(objectiveId);
    setState(() {
      if (wasMarked) {
        _marked.remove(objectiveId);
      } else {
        _marked.add(objectiveId);
      }
      _busyIds.add(objectiveId);
    });

    try {
      final useCase = await ref.read(markCompletionUseCaseProvider.future);
      final result = await useCase.execute(
        challengeId: widget.challenge.id,
        objectiveId: objectiveId,
        date: widget.day,
        completed: !wasMarked,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(challengeDetailProvider(widget.challenge.id));
          ref.invalidate(challengesListProvider);
        },
        failure: (failure) {
          setState(() {
            if (wasMarked) {
              _marked.add(objectiveId);
            } else {
              _marked.remove(objectiveId);
            }
          });
          context.showSnackBar(
            failure.message.isEmpty ? l.errorSavingMark : failure.message,
            isError: true,
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasMarked) {
          _marked.add(objectiveId);
        } else {
          _marked.remove(objectiveId);
        }
      });
      context.showSnackBar(l.errorSavingMark, isError: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(objectiveId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final objectives = widget.challenge.objectives;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.markToday, style: context.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l.markTodayHint,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final o in objectives)
              _ObjectiveRow(
                title: o.title,
                checked: _marked.contains(o.id),
                busy: _busyIds.contains(o.id),
                onChanged: () => _toggle(o.id),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.done),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  const _ObjectiveRow({
    required this.title,
    required this.checked,
    required this.busy,
    required this.onChanged,
  });

  final String title;
  final bool checked;
  final bool busy;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onChanged,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
                      onChanged: (_) => onChanged(),
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
