import 'package:freezed_annotation/freezed_annotation.dart';

part 'objective.freezed.dart';
part 'objective.g.dart';

@freezed
class Objective with _$Objective {
  const factory Objective({
    required String id,
    required String title,
    String? description,
    required DateTime createdAt,
    @Default(false) bool isPenalty,
    DateTime? expiresAt,
  }) = _Objective;

  const Objective._();

  bool get isValid => title.isNotEmpty;

  /// True when this objective should still appear on Today on [day]. A null
  /// [expiresAt] means it never expires (regular objective).
  bool isLiveOn(DateTime day) {
    if (expiresAt == null) return true;
    return day.isBefore(expiresAt!);
  }

  factory Objective.fromJson(Map<String, dynamic> json) =>
      _$ObjectiveFromJson(json);
}
