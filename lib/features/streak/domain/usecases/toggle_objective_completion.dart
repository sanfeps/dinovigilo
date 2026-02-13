import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/streak/domain/entities/daily_completion.dart';
import 'package:dinovigilo/features/streak/domain/repositories/streak_repository.dart';

class ToggleObjectiveCompletionUseCase {
  final StreakRepository _repository;

  const ToggleObjectiveCompletionUseCase(this._repository);

  Future<Result<DailyCompletion>> execute({
    required String completionId,
    required bool completed,
  }) {
    return _repository.toggleCompletion(completionId, completed);
  }
}
