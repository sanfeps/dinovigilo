import 'package:dinovigilo/features/sprint/domain/entities/day_objective_mapping.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sprint.freezed.dart';
part 'sprint.g.dart';

@freezed
class Sprint with _$Sprint {
  const factory Sprint({
    required String id,
    required List<DayObjectiveMapping> dayMappings,
    required bool isActive,
  }) = _Sprint;

  const Sprint._();

  /// Index of the weekday within the cycle: 0=Monday .. 6=Sunday.
  int getDayOfSprint(DateTime date) => date.weekday - 1;

  List<String> getObjectiveIdsForDay(int dayOfSprint) {
    return dayMappings
        .where((mapping) => mapping.dayOfSprint == dayOfSprint)
        .map((mapping) => mapping.objectiveId)
        .toList();
  }

  factory Sprint.fromJson(Map<String, dynamic> json) =>
      _$SprintFromJson(json);
}
