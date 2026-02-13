import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/objectives/presentation/providers/objective_providers.dart';
import 'package:dinovigilo/features/sprint/data/datasources/sprint_local_datasource.dart';
import 'package:dinovigilo/features/sprint/data/repositories/sprint_repository_impl.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';
import 'package:dinovigilo/features/sprint/domain/repositories/sprint_repository.dart';
import 'package:dinovigilo/features/sprint/domain/usecases/create_sprint.dart';
import 'package:dinovigilo/features/sprint/domain/usecases/get_active_sprint.dart';
import 'package:dinovigilo/features/sprint/domain/usecases/get_objectives_for_day.dart';
import 'package:dinovigilo/features/sprint/domain/usecases/update_sprint.dart';

part 'sprint_providers.g.dart';

@Riverpod(keepAlive: true)
SprintLocalDatasource sprintLocalDatasource(SprintLocalDatasourceRef ref) {
  final db = ref.watch(databaseProvider);
  return SprintLocalDatasource(db);
}

@Riverpod(keepAlive: true)
SprintRepository sprintRepository(SprintRepositoryRef ref) {
  final datasource = ref.watch(sprintLocalDatasourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return SprintRepositoryImpl(datasource, analytics);
}

@riverpod
CreateSprintUseCase createSprintUseCase(CreateSprintUseCaseRef ref) {
  return CreateSprintUseCase(ref.watch(sprintRepositoryProvider));
}

@riverpod
GetActiveSprintUseCase getActiveSprintUseCase(
  GetActiveSprintUseCaseRef ref,
) {
  return GetActiveSprintUseCase(ref.watch(sprintRepositoryProvider));
}

@riverpod
GetObjectivesForDayUseCase getObjectivesForDayUseCase(
  GetObjectivesForDayUseCaseRef ref,
) {
  return GetObjectivesForDayUseCase(
    ref.watch(sprintRepositoryProvider),
    ref.watch(objectiveRepositoryProvider),
  );
}

@riverpod
UpdateSprintUseCase updateSprintUseCase(UpdateSprintUseCaseRef ref) {
  return UpdateSprintUseCase(ref.watch(sprintRepositoryProvider));
}

@riverpod
Stream<Sprint?> activeSprintStream(ActiveSprintStreamRef ref) {
  // Re-subscribe when objectives change (handles cascade deletes updating mappings)
  ref.watch(objectivesStreamProvider);

  final repository = ref.watch(sprintRepositoryProvider);
  return repository.watchActiveSprint();
}
