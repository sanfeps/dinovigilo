# DinoVigilo — Development Guide

## Quick Start

```bash
# Enter the dev shell (run this once per terminal session)
nix develop

# Run the app on Linux desktop (fastest for development)
flutter run -d linux

# OR without entering the shell first:
nix develop --command flutter run -d linux
```

---

## Most Used Commands

```bash
# Run app
flutter run -d linux

# Hot reload (while app is running)
r

# Hot restart (reloads all state, needed after DB schema changes)
R

# Quit
q

# After modifying any @freezed, @riverpod, or Drift table:
flutter pub run build_runner build --delete-conflicting-outputs

# After adding/editing ARB translation keys:
flutter gen-l10n

# Static analysis
flutter analyze

# Run tests
flutter test
```

> All commands assume you're inside `nix develop`. If running from outside, prefix with `nix develop --command`.

---

## Release Workflow

### 1. Bump version in pubspec.yaml
```yaml
version: X.Y.Z+N   # versionName+versionCode — must match the GitHub tag
```
Rule: `versionCode` (`N`) increments by 1 each release. `versionName` matches the tag exactly.

| Release | pubspec version |
|---------|----------------|
| v0.1.0  | 0.1.0+1        |
| v0.2.0  | 0.2.0+2        |
| v0.3.0  | 0.3.0+3        |
| v0.4.0  | 0.4.0+4        |

### 2. Commit changes
Use conventional commits (in English):
```bash
git add <files>
git commit -m "feat: short description of what was added"
git commit -m "fix: short description of what was fixed"
git push
```

### 3. Build APK
```bash
flutter build apk
```

**If build fails with `AAPT2 Daemon startup failed`** (NixOS issue):
```bash
# Find and patch the aapt2 binary
nix develop --command sh -c '
  for f in $(find ~/.gradle/caches -name "aapt2" -type f); do
    patchelf --set-interpreter "$(patchelf --print-interpreter $(which bash))" "$f"
    echo "Patched: $f"
  done
'
# Then retry: flutter build apk
```
This needs to be redone if Gradle updates aapt2 (rare).

### 4. Create GitHub release + upload APK
```bash
# Create release with notes
gh release create vX.Y.Z --title 'vX.Y.Z' --notes-file /tmp/notes.md

# Upload APK
gh release upload vX.Y.Z build/app/outputs/flutter-apk/app-release.apk
```

### 5. Obtainium (auto-updates on Android)
- Obtainium compares the APK's internal `versionName` with the GitHub tag.
- They **must match** exactly (e.g. tag `v0.3.0` → pubspec `0.3.0+3`).
- If they drift, users get stuck and have to reinstall manually.

---

## Database Schema History

| Version | Change |
|---------|--------|
| v1 | Initial schema |
| v2 | Recreated `pending_eggs` with `days_incubated` + `is_paused` |
| v3 | Added `pre_break_streak` to `streak_status` |
| v4 | Added `duration_days` to `sprints` (default 14) |

Schema version is in `lib/core/database/app_database.dart` → `schemaVersion`.
Migrations are in `onUpgrade`. **Increment schema version whenever you add/modify a table.**

After a schema change: the app needs a **cold restart** (not hot reload) to run the migration.

---

## Feature Status

- [x] Objectives CRUD
- [x] Sprint config (14 days → now configurable 1–4 weeks)
- [x] Streak tracking + recovery mode
- [x] Yesterday buffer (grace period to recover a missed day)
- [x] Egg incubation system
- [x] Dinosaur collection (50 species, 5 rarities)
- [x] History calendar + statistics
- [x] Notifications (daily reminder, egg events, streak events)
- [x] Settings (language, notifications, reminder time)
- [x] Debug tab (for testing — remove before final release)

---

## Testing Features via Debug Tab

The **Debug** tab (last tab) lets you simulate states without waiting real days:

| Button | What it does |
|--------|-------------|
| Set 29/30/60 Days | Set streak + totalPerfectDays |
| Streak +10 / +50 | Increment streak |
| **Break Streak** | Simulates a real streak break: sets `preBreakStreak`, `lastPerfectDay = yesterday`, `isActive = false`. Then go to **Today** tab to see the yellow buffer card. |
| Complete Recovery | Reactivates streak after recovery |
| Reset All | Wipes streak back to zero |
| Advance Eggs +1 | Manually advance egg incubation |
| Check Egg Hatching | Force-check if any eggs are ready |

### Testing the Yesterday Buffer card:
1. Make sure you have an **active sprint** with objectives assigned to **yesterday's date**
2. Debug → **Break Streak**
3. Switch to **Today** tab → yellow amber card appears
4. Check all objectives → streak auto-restores

---

## Architecture Overview

```
lib/
├── core/           # DB, constants, providers, services, utils
├── features/
│   ├── objectives/ # CRUD
│   ├── sprint/     # Sprint config + day assignment
│   ├── streak/     # Today screen, streak logic, yesterday buffer
│   ├── dinosaurs/  # Egg incubation + collection
│   ├── history/    # Calendar + stats
│   ├── settings/   # Preferences + i18n
│   └── debug/      # Debug controls (remove before release)
└── shared/         # Theme, widgets, extensions
```

**Key patterns:**
- State: Riverpod (`@riverpod` + code gen)
- DB: Drift (SQLite), `lib/core/database/`
- Models: Freezed
- i18n: ARB files in `lib/l10n/` → access via `context.l10n.key`
- Result monad: `Result<T>` = `Success | Failure`

**Tab order:** History(0) · Sprint(1) · **Today(2)** · Incubator(3) · Collection(4) · Debug(5)

---

## Common Gotchas

1. **After any schema change** → cold restart the app (quit + rerun), not hot reload.
2. **After modifying `@freezed`/`@riverpod`/Drift tables** → run `build_runner`.
3. **After adding l10n keys to ARB files** → run `flutter gen-l10n` before analyzing.
4. **`flutter_local_notifications` on Linux** → `zonedSchedule()` throws, always wrapped in try-catch. `show()` works.
5. **Drift import conflicts** → `sprint_local_datasource.dart` uses `hide Sprint`, `streak_local_datasource.dart` uses `hide Objective, Sprint`.
6. **aapt2 on NixOS** → needs `patchelf` after every Gradle cache invalidation (see Release Workflow above).
7. **Obtainium version sync** → `pubspec.yaml` versionName must equal the GitHub release tag.
