import 'package:flutter/material.dart';
import 'package:dinovigilo/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/debug/debug_screen.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/providers/egg_providers.dart';
import 'package:dinovigilo/features/settings/presentation/providers/settings_providers.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/screens/collection_screen.dart';
import 'package:dinovigilo/features/dinosaurs/presentation/screens/incubator_screen.dart';
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
    TodayScreen(onNavigateToIncubator: () => _navigateToTab(3)),
    const IncubatorScreen(),
    const CollectionScreen(),
    const DebugScreen(),
  ];

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
            label: context.l10n.incubator,
          ),
          NavigationDestination(
            icon: const Icon(Icons.catching_pokemon_outlined),
            selectedIcon: const Icon(Icons.catching_pokemon),
            label: context.l10n.collection,
          ),
          const NavigationDestination(
            icon: Icon(Icons.bug_report_outlined),
            selectedIcon: Icon(Icons.bug_report),
            label: 'Debug',
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
