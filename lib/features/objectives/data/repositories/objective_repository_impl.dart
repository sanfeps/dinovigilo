import 'package:dinovigilo/core/error/exceptions.dart';
import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/services/analytics_service.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/objectives/data/datasources/objective_local_datasource.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/domain/repositories/objective_repository.dart';

class ObjectiveRepositoryImpl implements ObjectiveRepository {
  final ObjectiveLocalDatasource _datasource;
  final AnalyticsService _analytics;

  const ObjectiveRepositoryImpl(this._datasource, this._analytics);

  @override
  Future<Result<List<Objective>>> getAll() async {
    try {
      final objectives = await _datasource.getAll();
      return Result.success(objectives);
    } on DatabaseException catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(DataFailure(e.message));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Objective>> getById(String id) async {
    try {
      final objective = await _datasource.getById(id);
      return Result.success(objective);
    } on NotFoundException catch (e) {
      return Result.failure(NotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(DataFailure(e.message));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Objective>> create(Objective objective) async {
    try {
      final created = await _datasource.insert(objective);
      _analytics.logEvent('objective_created', {'id': created.id});
      return Result.success(created);
    } on DatabaseException catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(DataFailure(e.message));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> update(Objective objective) async {
    try {
      await _datasource.updateObj(objective);
      _analytics.logEvent('objective_updated', {'id': objective.id});
      return Result.success(null);
    } on NotFoundException catch (e) {
      return Result.failure(NotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(DataFailure(e.message));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _datasource.deleteObj(id);
      _analytics.logEvent('objective_deleted', {'id': id});
      return Result.success(null);
    } on NotFoundException catch (e) {
      return Result.failure(NotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(DataFailure(e.message));
    } catch (e) {
      _analytics.logError(e, StackTrace.current);
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<Objective>> watchAll() {
    return _datasource.watchAll();
  }
}
