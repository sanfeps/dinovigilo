import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_objective_mapping.freezed.dart';
part 'day_objective_mapping.g.dart';

@freezed
class DayObjectiveMapping with _$DayObjectiveMapping {
  const factory DayObjectiveMapping({
    required String id,
    required int dayOfSprint,
    required String objectiveId,
  }) = _DayObjectiveMapping;

  factory DayObjectiveMapping.fromJson(Map<String, dynamic> json) =>
      _$DayObjectiveMappingFromJson(json);
}
