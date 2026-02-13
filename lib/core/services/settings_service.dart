import 'package:shared_preferences/shared_preferences.dart';

import 'package:dinovigilo/features/settings/domain/entities/app_settings.dart';

class SettingsService {
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';
  static const _keyLocaleOverride = 'locale_override';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await _preferences;
    return AppSettings(
      notificationsEnabled: prefs.getBool(_keyNotificationsEnabled) ?? true,
      reminderHour: prefs.getInt(_keyReminderHour) ?? 9,
      reminderMinute: prefs.getInt(_keyReminderMinute) ?? 0,
      localeOverride: prefs.getString(_keyLocaleOverride),
    );
  }

  Future<void> saveNotificationsEnabled(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyNotificationsEnabled, value);
  }

  Future<void> saveReminderTime(int hour, int minute) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  Future<void> saveLocaleOverride(String? locale) async {
    final prefs = await _preferences;
    if (locale == null) {
      await prefs.remove(_keyLocaleOverride);
    } else {
      await prefs.setString(_keyLocaleOverride, locale);
    }
  }
}
