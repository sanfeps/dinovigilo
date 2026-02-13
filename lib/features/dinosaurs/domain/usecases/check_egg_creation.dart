import 'package:dinovigilo/core/constants/app_constants.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_rarity.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/pending_egg.dart';
import 'package:dinovigilo/features/dinosaurs/domain/repositories/egg_repository.dart';
import 'package:dinovigilo/features/streak/domain/entities/streak_status.dart';
import 'package:uuid/uuid.dart';

class CheckEggCreationUseCase {
  final EggRepository _repository;

  const CheckEggCreationUseCase(this._repository);

  /// Creates a new egg if totalPerfectDays hit a 30-day milestone.
  /// Returns the newly created egg, or null if no milestone was reached.
  Future<Result<PendingEgg?>> execute(StreakStatus status) async {
    if (status.totalPerfectDays == 0) return Result.success(null);
    if (status.totalPerfectDays % AppConstants.daysPerEgg != 0) {
      return Result.success(null);
    }

    final rarity = DinosaurRarity.rollRarity(status.currentStreak);

    final egg = PendingEgg(
      id: const Uuid().v4(),
      rarity: rarity,
      totalDaysNeeded: rarity.hatchingDays,
    );

    final result = await _repository.createEgg(egg);
    return result.map((_) => egg);
  }
}
