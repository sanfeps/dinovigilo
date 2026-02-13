import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/features/streak/domain/repositories/streak_repository.dart';

class GetDailyCompletionsUseCase {
  final StreakRepository _repository;

  const GetDailyCompletionsUseCase(this._repository);

  Future<Result<List<DailyCompletion>>> execute(DateTime date) {
    return _repository.getCompletionsForDate(date);
  }
}
