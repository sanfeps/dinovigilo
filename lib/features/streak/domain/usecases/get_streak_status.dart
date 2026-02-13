import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:dinovigilo/features/streak/domain/repositories/streak_repository.dart';

class GetStreakStatusUseCase {
  final StreakRepository _repository;

  const GetStreakStatusUseCase(this._repository);

  Future<Result<StreakStatus>> execute() {
    return _repository.getStreakStatus();
  }
}
