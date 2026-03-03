import 'package:dinovigilo/core/constants/app_constants.dart';
import 'package:dinovigilo/features/sprint/domain/entities/day_objective_mapping.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sprint.freezed.dart';
part 'sprint.g.dart';

@freezed
class Sprint with _$Sprint {
  const factory Sprint({
    required String id,
    required DateTime startDate,
    required List<DayObjectiveMapping> dayMappings,
    required bool isActive,
    @Default(AppConstants.sprintDurationDays) int durationDays,
  }) = _Sprint;

  const Sprint._();

  DateTime get endDate =>
      startDate.add(Duration(days: durationDays));

  bool isDateInSprint(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly =
        DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return !dateOnly.isBefore(startOnly) && dateOnly.isBefore(endOnly);
  }

  int getDayOfSprint(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly =
        DateTime(startDate.year, startDate.month, startDate.day);
    return dateOnly.difference(startOnly).inDays;
  }

  List<String> getObjectiveIdsForDay(int dayOfSprint) {
    return dayMappings
        .where((mapping) => mapping.dayOfSprint == dayOfSprint)
        .map((mapping) => mapping.objectiveId)
        .toList();
  }

  factory Sprint.fromJson(Map<String, dynamic> json) =>
      _$SprintFromJson(json);
}
