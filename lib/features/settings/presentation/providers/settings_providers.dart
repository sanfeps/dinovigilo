import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/core/services/settings_service.dart';
import 'package:dinovigilo/features/settings/domain/entities/app_settings.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
SettingsService settingsService(SettingsServiceRef ref) {
  return SettingsService();
}

@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    final service = ref.watch(settingsServiceProvider);
    return service.loadSettings();
  }

  Future<void> toggleNotifications(bool enabled) async {
    final service = ref.read(settingsServiceProvider);
    await service.saveNotificationsEnabled(enabled);

    final notifications = ref.read(notificationServiceProvider);
    if (enabled) {
      final current = state.valueOrNull ?? const AppSettings();
      await notifications.scheduleDailyReminder(
        TimeOfDay(hour: current.reminderHour, minute: current.reminderMinute),
      );
    } else {
      await notifications.cancelDailyReminder();
    }

    state = AsyncData(
      (state.valueOrNull ?? const AppSettings()).copyWith(
        notificationsEnabled: enabled,
      ),
    );
  }

  Future<void> updateReminderTime(int hour, int minute) async {
    final service = ref.read(settingsServiceProvider);
    await service.saveReminderTime(hour, minute);

    final current = state.valueOrNull ?? const AppSettings();
    if (current.notificationsEnabled) {
      final notifications = ref.read(notificationServiceProvider);
      await notifications.scheduleDailyReminder(
        TimeOfDay(hour: hour, minute: minute),
      );
    }

    state = AsyncData(
      current.copyWith(reminderHour: hour, reminderMinute: minute),
    );
  }

  Future<void> updateLocale(String? locale) async {
    final service = ref.read(settingsServiceProvider);
    await service.saveLocaleOverride(locale);

    state = AsyncData(
      (state.valueOrNull ?? const AppSettings()).copyWith(
        localeOverride: locale,
      ),
    );
  }
}
