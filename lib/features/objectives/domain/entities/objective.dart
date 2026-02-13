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
  }) = _Objective;

  const Objective._();

  bool get isValid => title.isNotEmpty;

  factory Objective.fromJson(Map<String, dynamic> json) =>
      _$ObjectiveFromJson(json);
}
