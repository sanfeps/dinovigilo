# DinoVigilo — Claude Code Guide

## Project Overview

**DinoVigilo** is a Flutter/Dart mobile app for daily objective tracking with dinosaur gamification (egg hatching, dino collection). Users build streaks by completing daily objectives, earn eggs every 30 perfect days, and hatch dinosaurs of varying rarities.

- **Dark mode only** (no light theme)
- **Emoji placeholders** for dinosaur assets (no image files required for development)
- **Nix flake** (`android-nixpkgs`) for reproducible dev environment
- All 8 phases complete; ongoing UI/feature work

---

## Running the App (Graphical Mode)

### Option A — Linux Desktop (fastest for development)
```bash
nix develop --command flutter run -d linux
```

### Option B — Android Emulator
```bash
# First time: create an AVD
nix develop --command avdmanager create avd -n pixel6 \
  -k 'system-images;android-34;google_apis_playstore;x86_64' -d pixel_6

# Start the emulator (in a separate terminal)
nix develop --command emulator -avd pixel6

# Then run the app (once emulator is booted)
nix develop --command flutter run
```

### Option C — Physical Android device (USB)
```bash
# List connected devices
nix develop --command flutter devices

# Run on a specific device
nix develop --command flutter run -d <device-id>
```

> **Note:** The `LD_LIBRARY_PATH` in `flake.nix` is pre-configured for the emulator's Qt frontend (Wayland/X11 libs). Always use `nix develop --command` so this env is active.

---

## Other Key Commands

```bash
# Code generation (Drift, Riverpod, Freezed) — run after modifying annotated files
nix develop --command flutter pub run build_runner build --delete-conflicting-outputs

# Regenerate l10n after editing ARB files
nix develop --command flutter gen-l10n

# Static analysis
nix develop --command flutter analyze

# Run tests
nix develop --command flutter test

# Build Android APK (see NixOS notes below)
nix develop --command flutter build apk

# Enter the dev shell interactively (avoids typing 'nix develop --command' each time)
nix develop
```

---

## Tech Stack

| Concern | Library |
|---|---|
| State Management | `flutter_riverpod ^2.4.0` + `riverpod_annotation` |
| Database | `drift ^2.14.0` (SQLite) |
| Data Models | `freezed_annotation ^2.4.0` |
| Notifications | `flutter_local_notifications ^17.0.0` |
| Settings | `shared_preferences ^2.2.0` |
| i18n | `flutter_localizations` + `intl ^0.20.2` |
| UI animations | `flutter_animate ^4.5.0` |
| IDs | `uuid ^4.2.0` |
| Code gen | `build_runner`, `drift_dev`, `riverpod_generator`, `freezed`, `json_serializable` |

---

## Architecture: Clean Architecture

```
Presentation  →  Domain  →  Data  →  Core
(UI, Providers)  (Entities, UseCases, Repo interfaces)  (Datasources, Repo impls)  (DB, Services, Utils)
```

Each feature under `lib/features/<feature>/` has:
- `domain/entities/` — Freezed immutable models
- `domain/repositories/` — abstract interfaces
- `domain/usecases/` — single-responsibility use cases
- `data/datasources/` — Drift DB queries
- `data/repositories/` — repo implementations
- `presentation/providers/` — Riverpod providers
- `presentation/screens/` — full-page widgets
- `presentation/widgets/` — reusable sub-widgets

---

## File Structure

```
lib/
├── main.dart                          # Entry point; init services, ProviderContainer
├── app.dart                           # DinoVigiloApp + _HomeScreen (tabs)
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # sprintDurationDays=14, daysPerEgg=30, recoveryDaysRequired=3
│   │   └── dinosaur_species_data.dart # 50 species across 5 rarity tiers
│   ├── database/
│   │   ├── tables.dart                # Drift table definitions (8 tables, schema v2)
│   │   └── app_database.dart          # DB singleton, migrations, seeding
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart              # Sealed Failure types
│   ├── providers/
│   │   └── core_providers.dart        # keepAlive providers: DB, analytics, notifications
│   ├── services/
│   │   ├── notification_service.dart
│   │   ├── settings_service.dart      # SharedPreferences wrapper
│   │   └── analytics_service.dart
│   └── utils/
│       ├── result.dart                # Result<T> = Success | Failure monad
│       └── date_helpers.dart
├── features/
│   ├── objectives/                    # CRUD objectives
│   ├── sprint/                        # 14-day sprint configuration
│   ├── streak/                        # Today screen, streak tracking
│   ├── dinosaurs/                     # Egg incubation + dino collection
│   ├── history/                       # Calendar + statistics
│   ├── settings/                      # User preferences + localization
│   └── debug/                         # Debug screen (remove before release)
├── shared/
│   ├── theme/
│   │   ├── app_colors.dart            # Dark palette + rarity colors
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart             # ThemeData (Material 3, dark)
│   ├── extensions/
│   │   ├── context_extensions.dart    # context.l10n, context.theme, showSnackBar
│   │   └── datetime_extensions.dart
│   └── widgets/
│       ├── empty_state.dart
│       ├── error_display.dart
│       └── loading_indicator.dart
└── l10n/
    ├── app_en.arb                     # English (template)
    └── app_es.arb                     # Spanish
```

Generated localization output: `lib/l10n/app_localizations.dart`
Import as: `package:dinovigilo/l10n/app_localizations.dart`

---

## Navigation (Tab-based)

Defined in `lib/app.dart` — `_HomeScreen` with `IndexedStack`.

| Index | Tab | Default? |
|---|---|---|
| 0 | History | |
| 1 | Sprint | |
| **2** | **Today** | **yes** |
| 3 | Incubator | |
| 4 | Collection | |
| 5 | Debug (temp) | |

Cross-tab navigation: `TodayScreen` receives `onNavigateToIncubator` callback.

---

## Database Schema (Drift, v2)

| Table | Key columns |
|---|---|
| `Objectives` | id, title, description?, createdAt |
| `Sprints` | id, startDate, isActive |
| `DayObjectiveMappings` | id, sprintId→Sprints, dayOfSprint, objectiveId→Objectives |
| `DailyCompletions` | id, date, objectiveId→Objectives, completed, completedAt? — unique(date,objectiveId) |
| `dinosaur_species` | id, name, emoji, rarity, description |
| `Dinosaurs` | id, speciesId→dinosaur_species, hatchedAt, streakDayWhenHatched |
| `PendingEggs` | id, rarity, totalDaysNeeded, daysIncubated(def=0), isPaused(def=false) |
| `streak_status` | id(always=1), currentStreak, totalPerfectDays, longestStreak, lastPerfectDay?, isActive, recoveryDaysNeeded |

**Tables with custom `@DataClassName`** (avoid import conflicts):
- `DayObjectiveMappings` → `DayObjectiveMappingRow`
- `DailyCompletions` → `DailyCompletionRow`
- `DinosaurSpeciesTable` → `DinosaurSpeciesRow`
- `PendingEggs` → `PendingEggRow`
- `StreakStatusTable` → `StreakStatusRow`

When importing app_database in datasources, use `hide Objective` if there's a name conflict with the domain entity.

---

## Domain Entities (key details)

**DinosaurRarity** (enum): `common | uncommon | rare | epic | legendary`
Hatching days: Common=20, Uncommon=25, Rare=30, Epic=35, Legendary=40

**StreakStatus**: `isInRecoveryMode` and `isHealthy` are computed getters.
`processDayEnd` resets `currentStreak` to 0 and sets `isActive: false` on streak break.

**PendingEgg**: `progress` = 0.0 if paused, otherwise `daysIncubated / totalDaysNeeded`.

**Rarity weights** by streak day: ≤60→Common, ≤120→Uncommon, ≤180→Rare, ≤270→Epic, >270→Legendary

---

## Riverpod Patterns

- Core providers in `core_providers.dart` use `keepAlive: true`
- Feature providers use `@riverpod` annotation + generated code
- Async state: `AsyncValue<T>` via `StreamProvider` or `FutureProvider`
- Mutable global state: `StateNotifier` (e.g., `AppSettingsNotifier`)
- Hatching dialog trigger: `recentlyHatchedDinosaursProvider` (StateProvider<List<Dinosaur>>), listened in `_HomeScreen`

---

## Localization

- Edit ARBs: `lib/l10n/app_en.arb` (template), `lib/l10n/app_es.arb`
- After adding keys: run `flutter gen-l10n` before `flutter analyze`
- Access in widgets: `context.l10n.yourKey` (via `ContextExtensions`)
- `intl` version pinned to `0.20.2` by `flutter_localizations` — always match

---

## Theme

All colors in `lib/shared/theme/app_colors.dart`. Key colors:
- Background: `#1A1A2E`, Surface: `#252541`
- Primary: `#FF6B35` (orange), Secondary: `#4A7C59` (green), Accent: `#FFD23F`
- Rarity: Common=grey, Uncommon=green, Rare=blue, Epic=purple, Legendary=gold

`CardTheme` constructor is `CardThemeData` (Flutter 3.38+ rename).

---

## Critical Gotchas

1. **`flutter_local_notifications` on Linux**: `zonedSchedule()` throws `UnimplementedError`. Always wrap in try-catch. `show()` works fine.

2. **`const Result.success([])` fails** — use `Result.success(const [])` instead.

3. **Generated code warnings**: Drift and Riverpod generate ~55 warnings about null checks / deprecated APIs. Safe to ignore.

4. **`hide Objective`**: When importing app_database in a datasource that also imports the `Objective` domain entity, use `hide Objective` on the DB import to avoid name conflicts.

5. **Sprint simplified UX**: Always shows config form. Uses `_loaded` flag to prevent re-populating form on rebuilds. `_existingSprint` tracks create vs update.

6. **ProcessDayEnd on streak break**: Sets both `isActive: false` AND `currentStreak: 0`.

7. **Egg incubation pause**: Paused on streak break, resumed on recovery complete.

---

## Android / NixOS Build Notes

Building Android APK on NixOS requires extra steps. Key issues:
- Extra SDK packages in `flake.nix`: `build-tools-35/36`, `platforms-android-35/36`, `ndk-28-2-13676358`, `cmake-3-22-1`
- Core library desugaring required in `android/app/build.gradle.kts` for `flutter_local_notifications`:
  ```kotlin
  isCoreLibraryDesugaringEnabled = true
  // + coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
  ```
- `aapt2` dynamically-linked binary needs patching after Gradle downloads it:
  ```bash
  patchelf --set-interpreter $NIX_LD ~/.gradle/caches/*/transforms/*/transformed/aapt2-*-linux/aapt2
  ```
  This is fragile — re-patch if Gradle cache updates.
- Long-term fix: enable `programs.nix-ld.enable = true` in NixOS system config.

---

## Code Generation

After modifying any of these, run `build_runner build`:
- `tables.dart` (Drift table definitions)
- Any file with `@riverpod`, `@freezed`, or `@JsonSerializable` annotations

```bash
nix develop --command flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Pending / Known Issues

- Debug tab (index 5) should be removed before release
- Dinosaur image assets are emoji placeholders — real art not yet added
- Linux notifications: daily reminder scheduling unsupported (silenced via try-catch)
