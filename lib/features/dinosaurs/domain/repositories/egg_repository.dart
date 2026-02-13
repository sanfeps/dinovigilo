import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_rarity.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_species.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/pending_egg.dart';

abstract class EggRepository {
  Future<Result<List<PendingEgg>>> getPendingEggs();
  Future<Result<PendingEgg>> createEgg(PendingEgg egg);
  Future<Result<Dinosaur>> hatchEgg(String eggId, Dinosaur dinosaur);
  Future<Result<void>> pauseAllEggs();
  Future<Result<void>> resumeAllEggs();
  Future<Result<void>> advanceAllEggs();
  Future<Result<List<Dinosaur>>> getAllDinosaurs();
  Future<Result<List<DinosaurSpecies>>> getSpeciesByRarity(
    DinosaurRarity rarity,
  );
  Future<Result<Set<String>>> getExistingSpeciesIds();
  Stream<List<PendingEgg>> watchPendingEggs();
  Stream<List<Dinosaur>> watchDinosaurs();
}
