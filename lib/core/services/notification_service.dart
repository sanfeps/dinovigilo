import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:dinovigilo/core/constants/app_constants.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleDailyReminder(TimeOfDay time);
  Future<void> cancelDailyReminder();
  Future<void> showEggCreatedNotification(int streakDay);
  Future<void> showEggHatchedNotification(Dinosaur dinosaur);
  Future<void> showRecoveryProgressNotification(int daysRemaining);
  Future<void> showRecoveryCompleteNotification();
  Future<void> showStreakBreakNotification();
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  @override
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  @override
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    try {
      await _notifications.zonedSchedule(
        0,
        'Time to check your objectives!',
        'Keep your streak alive today',
        _nextInstanceOfTime(time),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.dailyReminderChannelId,
            'Daily Reminders',
            channelDescription: 'Daily objective reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule daily reminder: $e');
    }
  }

  @override
  Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(0);
    } catch (e) {
      debugPrint('Failed to cancel daily reminder: $e');
    }
  }

  @override
  Future<void> showEggCreatedNotification(int streakDay) async {
    await _notifications.show(
      1,
      'New Egg Created!',
      'You earned a new egg at $streakDay days! Keep going!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.eggRewardsChannelId,
          'Egg Rewards',
          channelDescription: 'Notifications for egg rewards',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> showEggHatchedNotification(Dinosaur dinosaur) async {
    await _notifications.show(
      2,
      'Egg Hatched!',
      'A new dinosaur joined your collection!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.eggHatchingChannelId,
          'Egg Hatching',
          channelDescription: 'Notifications when eggs hatch',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> showRecoveryProgressNotification(int daysRemaining) async {
    final dayWord = daysRemaining > 1 ? 'days' : 'day';
    await _notifications.show(
      3,
      'Recovery Mode',
      '$daysRemaining more perfect $dayWord to resume your eggs!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.recoveryChannelId,
          'Recovery Mode',
          channelDescription: 'Recovery mode progress',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> showRecoveryCompleteNotification() async {
    await _notifications.show(
      4,
      'Welcome Back!',
      'Your eggs are cooking again! Keep up the great work!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.recoveryChannelId,
          'Recovery Mode',
          channelDescription: 'Recovery mode progress',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> showStreakBreakNotification() async {
    await _notifications.show(
      5,
      'Streak Broken',
      "Don't give up! Complete your recovery days to get back on track.",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.recoveryChannelId,
          'Recovery Mode',
          channelDescription: 'Recovery mode progress',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigation will be handled in future phases
  }
}
