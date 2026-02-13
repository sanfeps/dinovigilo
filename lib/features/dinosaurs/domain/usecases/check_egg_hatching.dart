import 'dart:math';

import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/repositories/egg_repository.dart';
import 'package:uuid/uuid.dart';

class CheckEggHatchingUseCase {
  final EggRepository _repository;

  const CheckEggHatchingUseCase(this._repository);

  /// Checks all pending eggs and hatches any that are ready.
  /// Returns the list of newly hatched dinosaurs.
  Future<Result<List<Dinosaur>>> execute() async {
    final eggsResult = await _repository.getPendingEggs();
    if (eggsResult.isFailure) return Result.failure(eggsResult.error);

    final existingIdsResult = await _repository.getExistingSpeciesIds();
    if (existingIdsResult.isFailure) {
      return Result.failure(existingIdsResult.error);
    }

    final existingSpeciesIds = existingIdsResult.data;
    final hatched = <Dinosaur>[];
    final random = Random();

    for (final egg in eggsResult.data) {
      if (!egg.isReadyToHatch) continue;

      final speciesResult = await _repository.getSpeciesByRarity(egg.rarity);
      if (speciesResult.isFailure) continue;

      final candidates = speciesResult.data;
      if (candidates.isEmpty) continue;

      // Prefer species not already in collection
      final newSpecies =
          candidates.where((s) => !existingSpeciesIds.contains(s.id)).toList();
      final pool = newSpecies.isNotEmpty ? newSpecies : candidates;
      final chosen = pool[random.nextInt(pool.length)];

      final dinosaur = Dinosaur(
        id: const Uuid().v4(),
        speciesId: chosen.id,
        hatchedAt: DateTime.now(),
        streakDayWhenHatched: egg.daysIncubated,
      );

      final hatchResult = await _repository.hatchEgg(egg.id, dinosaur);
      if (hatchResult.isSuccess) {
        hatched.add(hatchResult.data);
        existingSpeciesIds.add(chosen.id);
      }
    }

    return Result.success(hatched);
  }
}
