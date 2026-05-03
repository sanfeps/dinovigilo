import 'package:flutter/material.dart';
import 'package:dinovigilo/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/auth/presentation/providers/auth_providers.dart';
import 'package:dinovigilo/features/challenges/presentation/screens/challenges_screen.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/providers/egg_providers.dart';
import 'package:dinovigilo/features/settings/presentation/providers/settings_providers.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/screens/dinosaurs_screen.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/widgets/hatching_dialog.dart';
import 'package:dinovigilo/features/history/presentation/screens/history_screen.dart';
import 'package:dinovigilo/features/sprint/presentation/screens/sprint_config_screen.dart';
import 'package:dinovigilo/features/streak/presentation/screens/today_screen.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_theme.dart';

class DinoVigiloApp extends ConsumerWidget {
  const DinoVigiloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsNotifierProvider);
    final localeOverride = settingsAsync.valueOrNull?.localeOverride;

    return MaterialApp(
      title: 'DinoVigilo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeOverride != null ? Locale(localeOverride) : null,
      home: const _HomeScreen(),
    );
  }
}

class _HomeScreen extends ConsumerStatefulWidget {
  const _HomeScreen();

  @override
  ConsumerState<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<_HomeScreen> {
  int _currentIndex = 2;
  bool _hasShownHatchingDialog = false;

  late final List<Widget> _screens = [
    const HistoryScreen(),
    const SprintConfigScreen(),
    TodayScreen(onNavigateToIncubator: _openEggsTab),
    const DinosaursScreen(),
    const ChallengesScreen(),
  ];

  void _openEggsTab() {
    ref.read(dinosaursSubTabProvider.notifier).state = 0;
    _navigateToTab(3);
  }

  @override
  void initState() {
    super.initState();
    // Refresh the cached session once at startup so an expired token gets
    // cleared (the repo handles 401 → signOut). Fire-and-forget; the auth
    // stream will emit any state change.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final repo = await ref.read(authRepositoryProvider.future);
        await repo.refresh();
      } catch (_) {
        // Refresh is best-effort; failures are surfaced on the next API call.
      }
    });
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for recently hatched dinosaurs to show celebration dialog
    ref.listen<List<Dinosaur>>(
      recentlyHatchedDinosaursProvider,
      (previous, next) {
        if (next.isNotEmpty && !_hasShownHatchingDialog) {
          _hasShownHatchingDialog = true;
          _showHatchingDialogs(next);
        }
      },
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: context.l10n.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: const Icon(Icons.timer),
            label: context.l10n.sprint,
          ),
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: context.l10n.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.egg_outlined),
            selectedIcon: const Icon(Icons.egg),
            label: context.l10n.dinosaurs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shield_outlined),
            selectedIcon: const Icon(Icons.shield),
            label: context.l10n.challenges,
          ),
        ],
      ),
    );
  }

  Future<void> _showHatchingDialogs(List<Dinosaur> dinosaurs) async {
    for (final dinosaur in dinosaurs) {
      if (!mounted) return;
      await HatchingDialog.show(context, dinosaur);
    }
    if (mounted) {
      ref.read(recentlyHatchedDinosaursProvider.notifier).state = [];
      _hasShownHatchingDialog = false;
    }
  }
}
