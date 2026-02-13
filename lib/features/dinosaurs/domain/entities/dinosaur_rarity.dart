import 'dart:math';
import 'dart:ui';

enum DinosaurRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  String get displayName {
    return switch (this) {
      DinosaurRarity.common => 'Common',
      DinosaurRarity.uncommon => 'Uncommon',
      DinosaurRarity.rare => 'Rare',
      DinosaurRarity.epic => 'Epic',
      DinosaurRarity.legendary => 'Legendary',
    };
  }

  Color get color {
    return switch (this) {
      DinosaurRarity.common => const Color(0xFF9E9E9E),
      DinosaurRarity.uncommon => const Color(0xFF4CAF50),
      DinosaurRarity.rare => const Color(0xFF2196F3),
      DinosaurRarity.epic => const Color(0xFF9C27B0),
      DinosaurRarity.legendary => const Color(0xFFFFD700),
    };
  }

  /// Incubation days needed to hatch an egg of this rarity.
  int get hatchingDays {
    return switch (this) {
      DinosaurRarity.common => 20,
      DinosaurRarity.uncommon => 25,
      DinosaurRarity.rare => 30,
      DinosaurRarity.epic => 35,
      DinosaurRarity.legendary => 40,
    };
  }

  /// Guaranteed rarity tier for a given streak day (used as fallback).
  static DinosaurRarity forStreakDay(int streakDay) {
    if (streakDay <= 60) return DinosaurRarity.common;
    if (streakDay <= 120) return DinosaurRarity.uncommon;
    if (streakDay <= 180) return DinosaurRarity.rare;
    if (streakDay <= 270) return DinosaurRarity.epic;
    return DinosaurRarity.legendary;
  }

  /// Weighted probability table per streak tier.
  /// Returns weights for [common, uncommon, rare, epic, legendary].
  static List<int> _weightsForStreak(int currentStreak) {
    if (currentStreak <= 60) return const [70, 20, 8, 2, 0];
    if (currentStreak <= 120) return const [40, 35, 18, 5, 2];
    if (currentStreak <= 180) return const [20, 25, 30, 18, 7];
    if (currentStreak <= 270) return const [10, 15, 25, 30, 20];
    return const [5, 10, 15, 25, 45];
  }

  /// Roll a random rarity using weighted probabilities based on current streak.
  static DinosaurRarity rollRarity(int currentStreak, [Random? random]) {
    final weights = _weightsForStreak(currentStreak);
    final total = weights.reduce((a, b) => a + b);
    final rng = random ?? Random();
    var roll = rng.nextInt(total);

    for (var i = 0; i < values.length; i++) {
      roll -= weights[i];
      if (roll < 0) return values[i];
    }

    return DinosaurRarity.common;
  }
}
