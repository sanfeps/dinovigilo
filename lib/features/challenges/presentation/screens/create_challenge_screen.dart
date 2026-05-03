import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/features/challenges/domain/repositories/challenges_repository.dart';
import 'package:dinovigilo/features/challenges/presentation/providers/challenges_providers.dart';
import 'package:dinovigilo/features/friends/domain/entities/friend.dart';
import 'package:dinovigilo/features/friends/domain/entities/friendship.dart';
import 'package:dinovigilo/features/friends/presentation/providers/friends_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

const int _maxObjectives = 5;
const int _objectiveTitleMax = 60;
const int _penaltyMax = 120;

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _penaltyController = TextEditingController();
  final List<TextEditingController> _objectiveControllers = [
    TextEditingController(),
  ];
  Friend? _selectedOpponent;
  bool _submitting = false;

  @override
  void dispose() {
    _penaltyController.dispose();
    for (final c in _objectiveControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addObjectiveRow() {
    if (_objectiveControllers.length >= _maxObjectives) return;
    setState(() => _objectiveControllers.add(TextEditingController()));
  }

  void _removeObjectiveRow(int index) {
    if (_objectiveControllers.length <= 1) return;
    setState(() {
      final removed = _objectiveControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_selectedOpponent == null) {
      _showError(l.errorPickOpponent);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final drafts = <NewChallengeObjectiveDraft>[];
    for (final c in _objectiveControllers) {
      final text = c.text.trim();
      if (text.isEmpty) continue;
      drafts.add(NewChallengeObjectiveDraft(title: text));
    }
    if (drafts.isEmpty) {
      _showError(l.errorAtLeastOneObjective);
      return;
    }

    setState(() => _submitting = true);
    try {
      final useCase = await ref.read(createChallengeUseCaseProvider.future);
      final result = await useCase.execute(
        opponentId: _selectedOpponent!.id,
        penaltyObjective: _penaltyController.text.trim(),
        objectives: drafts,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          context.showSnackBar(l.challengeSent);
          Navigator.of(context).pop(true);
        },
        failure: (failure) => _showError(failure.message),
      );
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    context.showSnackBar(message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final friendshipsAsync = ref.watch(friendshipsListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.newChallenge)),
      body: friendshipsAsync.when(
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
        data: (friendships) {
          final accepted = friendships
              .where((f) => f.status == FriendshipStatus.accepted)
              .toList(growable: false);
          if (accepted.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l.errorNeedFriendsFirst,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return _buildForm(context, accepted);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Friendship> accepted) {
    final l = context.l10n;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l.opponentLabel, style: context.textTheme.titleSmall),
          const SizedBox(height: 8),
          _OpponentDropdown(
            friendships: accepted,
            selected: _selectedOpponent,
            onChanged: (f) => setState(() => _selectedOpponent = f),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(l.objectivesLabel,
                    style: context.textTheme.titleSmall),
              ),
              Text(
                '${_objectiveControllers.length}/$_maxObjectives',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _objectiveControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _objectiveControllers[i],
                      maxLength: _objectiveTitleMax,
                      enabled: !_submitting,
                      decoration: InputDecoration(
                        hintText: l.objectiveHint(i + 1),
                        counterText: '',
                      ),
                      validator: (v) {
                        if (i == 0 && (v == null || v.trim().isEmpty)) {
                          return l.errorAtLeastOneObjective;
                        }
                        return null;
                      },
                    ),
                  ),
                  if (_objectiveControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: l.removeObjective,
                      onPressed: _submitting ? null : () => _removeObjectiveRow(i),
                    ),
                ],
              ),
            ),
          if (_objectiveControllers.length < _maxObjectives)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _submitting ? null : _addObjectiveRow,
                icon: const Icon(Icons.add),
                label: Text(l.addObjective),
              ),
            ),
          const SizedBox(height: 24),
          Text(l.penaltyLabel, style: context.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            l.penaltyHelper,
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _penaltyController,
            maxLength: _penaltyMax,
            enabled: !_submitting,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_penaltyMax),
            ],
            decoration: InputDecoration(hintText: l.penaltyHint),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l.errorPenaltyRequired;
              return null;
            },
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(l.sendChallenge),
          ),
        ],
      ),
    );
  }
}

class _OpponentDropdown extends StatelessWidget {
  const _OpponentDropdown({
    required this.friendships,
    required this.selected,
    required this.onChanged,
  });

  final List<Friendship> friendships;
  final Friend? selected;
  final ValueChanged<Friend?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected?.id,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.person_outline),
        hintText: context.l10n.pickOpponent,
      ),
      items: [
        for (final f in friendships)
          DropdownMenuItem(
            value: f.friend.id,
            child: Row(
              children: [
                Text(
                  f.friend.avatarEmoji.isEmpty ? '🦖' : f.friend.avatarEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.friend.displayName.isEmpty
                        ? f.friend.username
                        : f.friend.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: (id) {
        if (id == null) {
          onChanged(null);
          return;
        }
        final match = friendships.firstWhere((f) => f.friend.id == id);
        onChanged(match.friend);
      },
    );
  }
}
