import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.asyncCode});

  final AsyncValue<String> asyncCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.yourInviteCode,
              style: context.textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            asyncCode.when(
              loading: () => const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                e is Failure ? e.message : context.l10n.errorGeneric,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
              data: (code) => _CodeDisplay(code: code),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.inviteCodeHint,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeDisplay extends StatelessWidget {
  const _CodeDisplay({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SelectableText(
            code,
            style: context.textTheme.displaySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFamily: 'monospace',
            ),
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.copy_outlined),
          tooltip: context.l10n.copyCode,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) {
              context.showSnackBar(context.l10n.codeCopied);
            }
          },
        ),
      ],
    );
  }
}
