import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/constants/dinosaur_species_data.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_species.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/providers/egg_providers.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/widgets/dinosaur_collection_tile.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/widgets/empty_state.dart';
import 'package:dinovigilo/shared/widgets/error_display.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

final _speciesMap = {
  for (final s in DinosaurSpeciesData.allSpecies) s.id: s,
};

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dinosAsync = ref.watch(dinosaursStreamProvider);
    final totalSpecies = DinosaurSpeciesData.allSpecies.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.collection),
      ),
      body: dinosAsync.when(
        data: (dinosaurs) {
          if (dinosaurs.isEmpty) {
            return EmptyState(
              message: context.l10n.noCollectionYet,
              icon: Icons.catching_pokemon,
            );
          }

          final uniqueSpeciesCount =
              dinosaurs.map((d) => d.speciesId).toSet().length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  context.l10n.speciesDiscovered(
                    uniqueSpeciesCount,
                    totalSpecies,
                  ),
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: dinosaurs.length,
                  itemBuilder: (context, index) {
                    final dino = dinosaurs[index];
                    final DinosaurSpecies? species = _speciesMap[dino.speciesId];
                    return DinosaurCollectionTile(
                      dinosaur: dino,
                      species: species,
                    )
                        .animate()
                        .fadeIn(
                          delay: (index * 50).ms,
                          duration: 400.ms,
                        )
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          delay: (index * 50).ms,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(dinosaursStreamProvider),
        ),
      ),
    );
  }
}
