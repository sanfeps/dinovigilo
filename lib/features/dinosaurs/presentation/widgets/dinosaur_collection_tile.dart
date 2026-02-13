import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_species.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class DinosaurCollectionTile extends StatefulWidget {
  final Dinosaur dinosaur;
  final DinosaurSpecies? species;

  const DinosaurCollectionTile({
    super.key,
    required this.dinosaur,
    required this.species,
  });

  @override
  State<DinosaurCollectionTile> createState() => _DinosaurCollectionTileState();
}

class _DinosaurCollectionTileState extends State<DinosaurCollectionTile> {
  double _scale = 1.0;

  Dinosaur get dinosaur => widget.dinosaur;
  DinosaurSpecies? get species => widget.species;

  @override
  Widget build(BuildContext context) {
    final rarityColor = species?.rarity.color ?? Colors.grey;

    return GestureDetector(
      onTap: () => _showDetail(context),
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: rarityColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                species?.emoji ?? '\u{1F995}',
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 8),
              Text(
                species?.name ?? dinosaur.speciesId,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  species?.rarity.displayName ?? '',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: rarityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final rarityColor = species?.rarity.color ?? Colors.grey;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              species?.emoji ?? '\u{1F995}',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            Text(
              species?.name ?? dinosaur.speciesId,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
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
            ),
            const SizedBox(height: 12),
            if (species?.description != null)
              Text(
                species!.description,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            Text(
              context.l10n.hatchedOn(
                DateFormat.yMMMd().format(dinosaur.hatchedAt),
              ),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
