import 'package:dinovigilo/core/error/exceptions.dart';
import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/services/analytics_service.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/sprint/data/datasources/sprint_local_datasource.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';
import 'package:dinovigilo/features/sprint/domain/repositories/sprint_repository.dart';

class SprintRepositoryImpl implements SprintRepository {
  final SprintLocalDatasource _datasource;
  final AnalyticsService _analytics;

  const SprintRepositoryImpl(this._datasource, this._analytics);

  @override
  Future<Result<Sprint?>> getActiveSprint() async {
    try {
      final sprint = await _datasource.getActiveSprint();
      return Result.success(sprint);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Sprint>> getById(String id) async {
    try {
      final sprint = await _datasource.getById(id);
      return Result.success(sprint);
    } on NotFoundException catch (e) {
      return Result.failure(NotFoundFailure(e.message));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Sprint>> create(Sprint sprint) async {
    try {
      final created = await _datasource.insert(sprint);
      _analytics.logEvent('sprint_created', {
        'id': created.id,
        'mappings': created.dayMappings.length,
      });
      return Result.success(created);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> update(Sprint sprint) async {
    try {
      await _datasource.updateSprint(sprint);
      _analytics.logEvent('sprint_updated', {'id': sprint.id});
      return Result.success(null);
    } on NotFoundException catch (e) {
      return Result.failure(NotFoundFailure(e.message));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deactivateAll() async {
    try {
      await _datasource.deactivateAll();
      return Result.success(null);
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<Sprint?> watchActiveSprint() {
    return _datasource.watchActiveSprint();
  }
}
