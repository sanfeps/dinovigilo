import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/app.dart';
import 'package:dinovigilo/core/providers/core_providers.dart';
import 'package:dinovigilo/features/settings/presentation/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Initialize services — wrapped in try-catch so the app always starts
  try {
    final notificationService = container.read(notificationServiceProvider);
    await notificationService.initialize();
    await notificationService.requestPermissions();

    final settings = await container.read(appSettingsNotifierProvider.future);
    if (settings.notificationsEnabled) {
      await notificationService.scheduleDailyReminder(
        TimeOfDay(
            hour: settings.reminderHour, minute: settings.reminderMinute),
      );
    }
  } catch (e) {
    debugPrint('Startup initialization error (non-fatal): $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DinoVigiloApp(),
    ),
  );
}
