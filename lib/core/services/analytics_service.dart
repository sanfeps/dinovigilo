import 'package:flutter/foundation.dart';

abstract class AnalyticsService {
  void logEvent(String name, Map<String, dynamic> params);
  void logError(Object error, StackTrace? stackTrace);
  void setUserId(String? userId);
  void setUserProperty(String name, String value);
}

class ConsoleAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, Map<String, dynamic> params) {
    debugPrint('Analytics Event: $name | $params');
  }

  @override
  void logError(Object error, StackTrace? stackTrace) {
    debugPrint('Analytics Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  void setUserId(String? userId) {
    debugPrint('Analytics User ID: $userId');
  }

  @override
  void setUserProperty(String name, String value) {
    debugPrint('Analytics User Property: $name = $value');
  }
}
