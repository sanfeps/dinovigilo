extension DateHelpers on DateTime {
  /// Returns a DateTime with only the date portion (no time).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Whether this date is the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Whether this date is yesterday relative to [other].
  bool isYesterday(DateTime other) {
    final yesterday = other.subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  /// Whether this date is today.
  bool get isToday => isSameDay(DateTime.now());

  /// Returns the start of the week (Monday).
  DateTime get startOfWeek {
    final daysFromMonday = weekday - DateTime.monday;
    return dateOnly.subtract(Duration(days: daysFromMonday));
  }

  /// Returns the number of calendar days between this and [other].
  int calendarDaysBetween(DateTime other) {
    return dateOnly.difference(other.dateOnly).inDays.abs();
  }
}
