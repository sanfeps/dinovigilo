import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/history/presentation/providers/history_providers.dart';
import 'package:dinovigilo/features/history/presentation/widgets/day_detail.dart';
import 'package:dinovigilo/features/history/presentation/widgets/month_calendar.dart';
import 'package:dinovigilo/features/history/presentation/widgets/stats_section.dart';
import 'package:dinovigilo/features/objectives/presentation/providers/objective_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _selectedDay = null;
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completionsAsync =
        ref.watch(monthCompletionsProvider(_currentMonth));
    final objectivesAsync = ref.watch(objectivesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.history),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar
            completionsAsync.when(
              data: (completions) => MonthCalendar(
                month: _currentMonth,
                completions: completions,
                selectedDay: _selectedDay,
                onDaySelected: (date) {
                  setState(() => _selectedDay = date);
                },
                onPreviousMonth: _goToPreviousMonth,
                onNextMonth: _goToNextMonth,
              ),
              loading: () => const SizedBox(
                height: 300,
                child: LoadingIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            // Day detail (when a day is selected)
            if (_selectedDay != null)
              completionsAsync.whenOrNull(
                    data: (completions) {
                      final dayCompletions = completions[_selectedDay] ?? [];
                      return objectivesAsync.whenOrNull(
                            data: (objectives) => DayDetail(
                              date: _selectedDay!,
                              completions: dayCompletions,
                              objectives: objectives,
                            ),
                          ) ??
                          const SizedBox.shrink();
                    },
                  ) ??
                  const SizedBox.shrink(),
            const SizedBox(height: 16),
            // Statistics
            const StatsSection(),
          ],
        ),
      ),
    );
  }
}
