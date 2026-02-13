import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_rarity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_egg.freezed.dart';
part 'pending_egg.g.dart';

@freezed
class PendingEgg with _$PendingEgg {
  const factory PendingEgg({
    required String id,
    required DinosaurRarity rarity,
    required int totalDaysNeeded,
    @Default(0) int daysIncubated,
    @Default(false) bool isPaused,
  }) = _PendingEgg;

  const PendingEgg._();

  int get daysRemaining => (totalDaysNeeded - daysIncubated).clamp(0, totalDaysNeeded);

  double get progress {
    if (isPaused) return 0.0;
    if (totalDaysNeeded <= 0) return 1.0;
    return (daysIncubated / totalDaysNeeded).clamp(0.0, 1.0);
  }

  bool get isReadyToHatch => !isPaused && daysIncubated >= totalDaysNeeded;

  factory PendingEgg.fromJson(Map<String, dynamic> json) =>
      _$PendingEggFromJson(json);
}
