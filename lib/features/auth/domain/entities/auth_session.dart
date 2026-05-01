import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:dinovigilo/features/auth/domain/entities/auth_user.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart';

@freezed
class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String token,
    required AuthUser user,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}
