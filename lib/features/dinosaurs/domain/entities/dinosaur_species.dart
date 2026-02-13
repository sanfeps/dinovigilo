import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_rarity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dinosaur_species.freezed.dart';
part 'dinosaur_species.g.dart';

@freezed
class DinosaurSpecies with _$DinosaurSpecies {
  const factory DinosaurSpecies({
    required String id,
    required String name,
    required String emoji,
    required DinosaurRarity rarity,
    required String description,
  }) = _DinosaurSpecies;

  factory DinosaurSpecies.fromJson(Map<String, dynamic> json) =>
      _$DinosaurSpeciesFromJson(json);
}
