import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

enum OutcomeKind { won, lost, tie }

class OutcomeEvent {
  const OutcomeEvent({
    required this.kind,
    required this.opponentName,
    this.penalty,
  });

  final OutcomeKind kind;
  final String opponentName;

  /// Only set for [OutcomeKind.lost].
  final String? penalty;
}

/// Sequentially shows one fullscreen dialog per [OutcomeEvent], waiting for
/// the user to dismiss each before moving on.
Future<void> showOutcomeDialogs(
  BuildContext context,
  List<OutcomeEvent> events,
) async {
  for (final event in events) {
    if (!context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'outcome',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => _OutcomeOverlay(event: event),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    );
  }
}

class _OutcomeOverlay extends StatelessWidget {
  const _OutcomeOverlay({required this.event});
  final OutcomeEvent event;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (color, title, subtitle, body) = switch (event.kind) {
      OutcomeKind.won => (
          AppColors.success,
          l.outcomeWonTitle,
          l.outcomeWonSubtitle(event.opponentName),
          const _WonAnimation(),
        ),
      OutcomeKind.lost => (
          AppColors.error,
          l.outcomeLostTitle,
          l.outcomeLostSubtitle(event.opponentName),
          const _LostAnimation(),
        ),
      OutcomeKind.tie => (
          AppColors.info,
          l.outcomeTieTitle,
          l.outcomeTieSubtitle,
          const _TieAnimation(),
        ),
    };

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 220,
                child: Center(child: body),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              if (event.kind == OutcomeKind.lost && event.penalty != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gavel,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          event.penalty!,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 400.ms).scale(
                      delay: 800.ms,
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 600.ms,
                    ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(180, 48),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l.outcomeContinue,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ).animate().fadeIn(delay: 1100.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _WonAnimation extends StatelessWidget {
  const _WonAnimation();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti emojis exploding outward in a circle.
        ..._confettiPositions().map((p) {
          return Text(p.emoji, style: const TextStyle(fontSize: 28))
              .animate()
              .fadeIn(delay: 250.ms, duration: 200.ms)
              .move(
                delay: 250.ms,
                begin: Offset.zero,
                end: p.offset,
                curve: Curves.easeOut,
                duration: 900.ms,
              )
              .fadeOut(delay: 950.ms, duration: 400.ms);
        }),
        // The trophy itself.
        const Text('🏆', style: TextStyle(fontSize: 110))
            .animate()
            .scale(
              begin: const Offset(0.2, 0.2),
              end: const Offset(1, 1),
              curve: Curves.elasticOut,
              duration: 800.ms,
            )
            .then(delay: 200.ms)
            .shimmer(duration: 1200.ms, color: AppColors.accent),
      ],
    );
  }

  static List<_ConfettiBit> _confettiPositions() {
    const emojis = ['⭐', '✨', '🎉', '💫', '🌟', '🎊'];
    const count = 12;
    final out = <_ConfettiBit>[];
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      const radius = 130.0;
      out.add(_ConfettiBit(
        emoji: emojis[i % emojis.length],
        offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      ));
    }
    return out;
  }
}

class _ConfettiBit {
  const _ConfettiBit({required this.emoji, required this.offset});
  final String emoji;
  final Offset offset;
}

class _LostAnimation extends StatelessWidget {
  const _LostAnimation();

  @override
  Widget build(BuildContext context) {
    return const Text('💀', style: TextStyle(fontSize: 130))
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
          duration: 500.ms,
        )
        .then(delay: 200.ms)
        .shake(hz: 6, duration: 700.ms, rotation: 0.08)
        .tint(color: AppColors.error.withValues(alpha: 0.3), duration: 600.ms);
  }
}

class _TieAnimation extends StatelessWidget {
  const _TieAnimation();

  @override
  Widget build(BuildContext context) {
    return const Text('🤝', style: TextStyle(fontSize: 120))
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
          duration: 700.ms,
        );
  }
}
