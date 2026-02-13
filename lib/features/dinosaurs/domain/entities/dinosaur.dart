import 'package:freezed_annotation/freezed_annotation.dart';

part 'dinosaur.freezed.dart';
part 'dinosaur.g.dart';

@freezed
class Dinosaur with _$Dinosaur {
  const factory Dinosaur({
    required String id,
    required String speciesId,
    required DateTime hatchedAt,
    required int streakDayWhenHatched,
  }) = _Dinosaur;

  factory Dinosaur.fromJson(Map<String, dynamic> json) =>
      _$DinosaurFromJson(json);
}
