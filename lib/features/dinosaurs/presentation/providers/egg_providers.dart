import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/dinosaurs/data/datasources/egg_local_datasource.dart';
import 'package:dinovigilo/features/dinosaurs/data/repositories/egg_repository_impl.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/pending_egg.dart';
import 'package:dinovigilo/features/dinosaurs/domain/repositories/egg_repository.dart';
import 'package:dinovigilo/features/dinosaurs/domain/usecases/advance_eggs.dart';
import 'package:dinovigilo/features/dinosaurs/domain/usecases/check_egg_creation.dart';
import 'package:dinovigilo/features/dinosaurs/domain/usecases/check_egg_hatching.dart';
import 'package:dinovigilo/features/dinosaurs/domain/usecases/get_collection.dart';
import 'package:dinovigilo/features/dinosaurs/domain/usecases/pause_all_eggs.dart';
import 'package:dinovigilo/features/dinosaurs/domain/usecases/resume_all_eggs.dart';

part 'egg_providers.g.dart';

@Riverpod(keepAlive: true)
EggLocalDatasource eggLocalDatasource(EggLocalDatasourceRef ref) {
  final db = ref.watch(databaseProvider);
  return EggLocalDatasource(db);
}

@Riverpod(keepAlive: true)
EggRepository eggRepository(EggRepositoryRef ref) {
  final datasource = ref.watch(eggLocalDatasourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return EggRepositoryImpl(datasource, analytics);
}

@riverpod
CheckEggCreationUseCase checkEggCreationUseCase(
  CheckEggCreationUseCaseRef ref,
) {
  return CheckEggCreationUseCase(ref.watch(eggRepositoryProvider));
}

@riverpod
CheckEggHatchingUseCase checkEggHatchingUseCase(
  CheckEggHatchingUseCaseRef ref,
) {
  return CheckEggHatchingUseCase(ref.watch(eggRepositoryProvider));
}

@riverpod
PauseAllEggsUseCase pauseAllEggsUseCase(PauseAllEggsUseCaseRef ref) {
  return PauseAllEggsUseCase(ref.watch(eggRepositoryProvider));
}

@riverpod
ResumeAllEggsUseCase resumeAllEggsUseCase(ResumeAllEggsUseCaseRef ref) {
  return ResumeAllEggsUseCase(ref.watch(eggRepositoryProvider));
}

@riverpod
AdvanceEggsUseCase advanceEggsUseCase(AdvanceEggsUseCaseRef ref) {
  return AdvanceEggsUseCase(ref.watch(eggRepositoryProvider));
}

@riverpod
GetCollectionUseCase getCollectionUseCase(GetCollectionUseCaseRef ref) {
  return GetCollectionUseCase(ref.watch(eggRepositoryProvider));
}

@riverpod
Stream<List<PendingEgg>> pendingEggsStream(PendingEggsStreamRef ref) {
  final repository = ref.watch(eggRepositoryProvider);
  return repository.watchPendingEggs();
}

@riverpod
Stream<List<Dinosaur>> dinosaursStream(DinosaursStreamRef ref) {
  final repository = ref.watch(eggRepositoryProvider);
  return repository.watchDinosaurs();
}

/// Manually defined StateProvider for recently hatched dinosaurs.
/// Populated by processDayEndOnStartup, consumed by app.dart to show hatching dialog.
final recentlyHatchedDinosaursProvider =
    StateProvider<List<Dinosaur>>((ref) => []);
