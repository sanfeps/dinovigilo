import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/services/analytics_service.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/dinosaurs/data/datasources/egg_local_datasource.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_rarity.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_species.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/pending_egg.dart';
import 'package:dinovigilo/features/dinosaurs/domain/repositories/egg_repository.dart';

class EggRepositoryImpl implements EggRepository {
  final EggLocalDatasource _datasource;
  final AnalyticsService _analytics;

  const EggRepositoryImpl(this._datasource, this._analytics);

  @override
  Future<Result<List<PendingEgg>>> getPendingEggs() async {
    try {
      final eggs = await _datasource.getPendingEggs();
      return Result.success(eggs);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PendingEgg>> createEgg(PendingEgg egg) async {
    try {
      final created = await _datasource.insertEgg(egg);
      _analytics.logEvent('egg_created', {
        'rarity': egg.rarity.name,
        'totalDaysNeeded': egg.totalDaysNeeded,
      });
      return Result.success(created);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Dinosaur>> hatchEgg(String eggId, Dinosaur dinosaur) async {
    try {
      await _datasource.hatchEgg(eggId, dinosaur);
      _analytics.logEvent('egg_hatched', {
        'speciesId': dinosaur.speciesId,
        'streakDay': dinosaur.streakDayWhenHatched,
      });
      return Result.success(dinosaur);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> pauseAllEggs() async {
    try {
      await _datasource.pauseAllEggs();
      _analytics.logEvent('eggs_paused', {});
      return Result.success(null);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> resumeAllEggs() async {
    try {
      await _datasource.resumeAllEggs();
      _analytics.logEvent('eggs_resumed', {});
      return Result.success(null);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> advanceAllEggs() async {
    try {
      await _datasource.advanceAllEggs();
      _analytics.logEvent('eggs_advanced', {});
      return Result.success(null);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Dinosaur>>> getAllDinosaurs() async {
    try {
      final dinosaurs = await _datasource.getAllDinosaurs();
      return Result.success(dinosaurs);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<DinosaurSpecies>>> getSpeciesByRarity(
    DinosaurRarity rarity,
  ) async {
    try {
      final species = await _datasource.getSpeciesByRarity(rarity);
      return Result.success(species);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Set<String>>> getExistingSpeciesIds() async {
    try {
      final ids = await _datasource.getExistingSpeciesIds();
      return Result.success(ids);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<PendingEgg>> watchPendingEggs() {
    return _datasource.watchPendingEggs();
  }

  @override
  Stream<List<Dinosaur>> watchDinosaurs() {
    return _datasource.watchDinosaurs();
  }
}
