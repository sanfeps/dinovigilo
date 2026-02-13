class AppConstants {
  AppConstants._();

  /// Number of days in a sprint cycle.
  static const int sprintDurationDays = 14;

  /// Number of perfect days required to earn an egg.
  static const int daysPerEgg = 30;

  /// Number of recovery days needed after a streak break.
  static const int recoveryDaysRequired = 3;

  /// Database file name.
  static const String databaseFileName = 'dinovigilo.sqlite';

  /// Notification channel IDs.
  static const String dailyReminderChannelId = 'daily_reminder';
  static const String eggRewardsChannelId = 'egg_rewards';
  static const String eggHatchingChannelId = 'egg_hatching';
  static const String recoveryChannelId = 'recovery';

  /// Default notification time (9:00 AM).
  static const int defaultNotificationHour = 9;
  static const int defaultNotificationMinute = 0;
}
