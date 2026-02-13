import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dinovigilo/core/database/app_database.dart';
import 'package:dinovigilo/core/services/analytics_service.dart';
import 'package:dinovigilo/core/services/notification_service.dart';

part 'core_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
AnalyticsService analyticsService(AnalyticsServiceRef ref) {
  return ConsoleAnalyticsService();
}

@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationServiceImpl();
}
