import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/objectives/data/datasources/objective_local_datasource.dart';
import 'package:dinovigilo/features/objectives/data/repositories/objective_repository_impl.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/domain/repositories/objective_repository.dart';
import 'package:dinovigilo/features/objectives/domain/usecases/create_objective.dart';
import 'package:dinovigilo/features/objectives/domain/usecases/delete_objective.dart';
import 'package:dinovigilo/features/objectives/domain/usecases/update_objective.dart';

part 'objective_providers.g.dart';

@Riverpod(keepAlive: true)
ObjectiveLocalDatasource objectiveLocalDatasource(
  ObjectiveLocalDatasourceRef ref,
) {
  final db = ref.watch(databaseProvider);
  return ObjectiveLocalDatasource(db);
}

@Riverpod(keepAlive: true)
ObjectiveRepository objectiveRepository(ObjectiveRepositoryRef ref) {
  final datasource = ref.watch(objectiveLocalDatasourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return ObjectiveRepositoryImpl(datasource, analytics);
}

@riverpod
CreateObjectiveUseCase createObjectiveUseCase(
  CreateObjectiveUseCaseRef ref,
) {
  return CreateObjectiveUseCase(ref.watch(objectiveRepositoryProvider));
}

@riverpod
UpdateObjectiveUseCase updateObjectiveUseCase(
  UpdateObjectiveUseCaseRef ref,
) {
  return UpdateObjectiveUseCase(ref.watch(objectiveRepositoryProvider));
}

@riverpod
DeleteObjectiveUseCase deleteObjectiveUseCase(
  DeleteObjectiveUseCaseRef ref,
) {
  return DeleteObjectiveUseCase(ref.watch(objectiveRepositoryProvider));
}

@riverpod
Stream<List<Objective>> objectivesStream(ObjectivesStreamRef ref) {
  final repository = ref.watch(objectiveRepositoryProvider);
  return repository.watchAll();
}
