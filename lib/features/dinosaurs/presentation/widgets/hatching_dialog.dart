import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:dinovigilo/core/constants/dinosaur_species_data.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_species.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class HatchingDialog extends StatelessWidget {
  final Dinosaur dinosaur;

  const HatchingDialog({super.key, required this.dinosaur});

  static Future<void> show(BuildContext context, Dinosaur dinosaur) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => HatchingDialog(dinosaur: dinosaur),
    );
  }

  @override
  Widget build(BuildContext context) {
    final species = _lookupSpecies(dinosaur.speciesId);
    final rarityColor = species?.rarity.color ?? Colors.grey;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            context.l10n.congratulations,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: -0.2, end: 0, duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            context.l10n.newDinosaurHatched,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rarityColor.withValues(alpha: 0.15),
              border: Border.all(
                color: rarityColor.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                species?.emoji ?? '\u{1F995}',
                style: const TextStyle(fontSize: 48),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                delay: 500.ms,
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),
          Text(
            species?.name ?? dinosaur.speciesId,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 900.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              species?.rarity.displayName ?? '',
              style: context.textTheme.labelMedium?.copyWith(
                color: rarityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 1100.ms, duration: 400.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                delay: 1100.ms,
                duration: 400.ms,
              ),
          if (species?.description != null) ...[
            const SizedBox(height: 12),
            Text(
              species!.description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 1300.ms, duration: 400.ms),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.awesome),
          ),
        ).animate().fadeIn(delay: 1500.ms, duration: 400.ms),
      ],
    );
  }

  static DinosaurSpecies? _lookupSpecies(String speciesId) {
    try {
      return DinosaurSpeciesData.allSpecies.firstWhere(
        (s) => s.id == speciesId,
      );
    } catch (_) {
      return null;
    }
  }
}
