import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/features/friends/presentation/providers/friends_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class AddByCodeForm extends ConsumerStatefulWidget {
  const AddByCodeForm({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<AddByCodeForm> createState() => _AddByCodeFormState();
}

class _AddByCodeFormState extends ConsumerState<AddByCodeForm> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
      context.showSnackBar(context.l10n.errorInvalidInviteCode, isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final useCase =
          await ref.read(addFriendByCodeUseCaseProvider.future);
      final result = await useCase.execute(code);
      if (!mounted) return;
      result.when(
        success: (_) {
          context.showSnackBar(context.l10n.friendRequestSent);
          _controller.clear();
          widget.onSuccess();
        },
        failure: (failure) {
          context.showSnackBar(_failureMessage(failure), isError: true);
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _failureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => context.l10n.errorNetwork,
      NotFoundFailure() => context.l10n.errorCodeNotFound,
      ValidationFailure(:final message) => _mapBackendValidation(message),
      AuthFailure() => context.l10n.errorInvalidCredentials,
      _ => context.l10n.errorGeneric,
    };
  }

  String _mapBackendValidation(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('cannot add yourself')) {
      return context.l10n.errorCannotAddSelf;
    }
    if (lower.contains('already exists')) {
      return context.l10n.errorAlreadyFriends;
    }
    if (lower.contains('invalid code')) {
      return context.l10n.errorInvalidInviteCode;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.addByCode,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_submitting,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9]'),
                      ),
                      TextInputFormatter.withFunction(
                        (_, n) => n.copyWith(text: n.text.toUpperCase()),
                      ),
                    ],
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: context.l10n.inviteCodePlaceholder,
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
