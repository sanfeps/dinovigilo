import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dinovigilo/core/constants/app_constants.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/presentation/providers/objective_providers.dart';
import 'package:dinovigilo/features/objectives/presentation/screens/objectives_screen.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';
import 'package:dinovigilo/features/sprint/presentation/providers/sprint_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/widgets/empty_state.dart';
import 'package:dinovigilo/shared/widgets/error_display.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class SprintConfigScreen extends ConsumerStatefulWidget {
  const SprintConfigScreen({super.key});

  @override
  ConsumerState<SprintConfigScreen> createState() => _SprintConfigScreenState();
}

class _SprintConfigScreenState extends ConsumerState<SprintConfigScreen> {
  static const int _cycleLength = AppConstants.weekLengthDays;

  int _selectedDay = DateTime.now().weekday - 1;
  bool _loaded = false;
  Sprint? _existingSprint;

  final Map<int, Set<String>> _dayObjectives = {};

  void _loadFromSprint(Sprint sprint) {
    _existingSprint = sprint;
    _dayObjectives.clear();
    for (final mapping in sprint.dayMappings) {
      if (mapping.dayOfSprint >= _cycleLength) continue;
      _dayObjectives
          .putIfAbsent(mapping.dayOfSprint, () => {})
          .add(mapping.objectiveId);
    }
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final sprintAsync = ref.watch(activeSprintStreamProvider);
    final objectivesAsync = ref.watch(objectivesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.sprint),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: context.l10n.objectives,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ObjectivesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: objectivesAsync.when(
        data: (objectives) {
          if (objectives.isEmpty) {
            return EmptyState(
              message: context.l10n.noObjectivesAvailable,
              icon: Icons.checklist,
            );
          }

          return sprintAsync.when(
            data: (sprint) {
              if (!_loaded && sprint != null) {
                _loadFromSprint(sprint);
              } else if (!_loaded) {
                _loaded = true;
              }

              return _buildConfigForm(context, objectives);
            },
            loading: () => const LoadingIndicator(),
            error: (error, _) => ErrorDisplay(
              message: error.toString(),
              onRetry: () => ref.invalidate(activeSprintStreamProvider),
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(objectivesStreamProvider),
        ),
      ),
    );
  }

  Widget _buildConfigForm(BuildContext context, List<Objective> objectives) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final todayWeekdayIndex = DateTime.now().weekday - 1;
    final selectedSet = _dayObjectives[_selectedDay] ?? const <String>{};

    return Column(
      children: [
        _buildDayPicker(context, localeName, todayWeekdayIndex),
        const Divider(height: 1),
        _buildDayHeader(context, localeName, todayWeekdayIndex),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: objectives.length,
            itemBuilder: (context, i) {
              final obj = objectives[i];
              final isSelected = selectedSet.contains(obj.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => _toggleObjective(obj.id),
                title: Text(obj.title),
                subtitle: (obj.description != null &&
                        obj.description!.isNotEmpty)
                    ? Text(
                        obj.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _hasAnyObjective() ? () => _save(context) : null,
              child: Text(context.l10n.save),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayPicker(
    BuildContext context,
    String localeName,
    int todayIndex,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Row(
        children: List.generate(_cycleLength, (i) {
          final hasObjectives = _dayObjectives[i]?.isNotEmpty ?? false;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _DayChip(
                dayIndex: i,
                localeName: localeName,
                isSelected: _selectedDay == i,
                isToday: todayIndex == i,
                hasObjectives: hasObjectives,
                onTap: () => setState(() => _selectedDay = i),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayHeader(
    BuildContext context,
    String localeName,
    int todayIndex,
  ) {
    final refDate = DateTime(2024, 1, 1).add(Duration(days: _selectedDay));
    final weekdayName = toBeginningOfSentenceCase(
      DateFormat.EEEE(localeName).format(refDate),
    );
    final isToday = _selectedDay == todayIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                weekdayName,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    context.l10n.today,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ActionChip(
                avatar: const Icon(Icons.select_all, size: 16),
                label: Text(context.l10n.applyToAllDays),
                onPressed: _applyToAll,
              ),
              ActionChip(
                avatar: const Icon(Icons.content_copy, size: 16),
                label: Text(context.l10n.copyFromPreviousDay),
                onPressed: _copyFromPrevious,
              ),
              ActionChip(
                avatar: const Icon(Icons.clear_all, size: 16),
                label: Text(context.l10n.clearDay),
                onPressed: _clearDay,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleObjective(String objectiveId) {
    setState(() {
      final set = _dayObjectives.putIfAbsent(_selectedDay, () => {});
      if (set.contains(objectiveId)) {
        set.remove(objectiveId);
      } else {
        set.add(objectiveId);
      }
    });
  }

  void _applyToAll() {
    setState(() {
      final currentSet = _dayObjectives[_selectedDay] ?? {};
      for (var i = 0; i < _cycleLength; i++) {
        _dayObjectives[i] = Set.from(currentSet);
      }
    });
  }

  void _copyFromPrevious() {
    setState(() {
      final prevIndex =
          (_selectedDay - 1 + _cycleLength) % _cycleLength;
      final previousSet = _dayObjectives[prevIndex] ?? {};
      _dayObjectives[_selectedDay] = Set.from(previousSet);
    });
  }

  void _clearDay() {
    setState(() {
      _dayObjectives[_selectedDay]?.clear();
    });
  }

  bool _hasAnyObjective() {
    return _dayObjectives.values.any((set) => set.isNotEmpty);
  }

  Future<void> _save(BuildContext context) async {
    final dayObjectiveIds = <int, List<String>>{};
    for (final entry in _dayObjectives.entries) {
      if (entry.value.isNotEmpty) {
        dayObjectiveIds[entry.key] = entry.value.toList();
      }
    }

    if (_existingSprint != null) {
      final useCase = ref.read(updateSprintUseCaseProvider);
      final result = await useCase.execute(
        sprint: _existingSprint!,
        dayObjectiveIds: dayObjectiveIds,
      );

      if (!mounted) return;

      result.when(
        success: (_) {
          context.showSnackBar(context.l10n.sprintUpdated);
        },
        failure: (error) =>
            context.showSnackBar(error.message, isError: true),
      );
    } else {
      final useCase = ref.read(createSprintUseCaseProvider);
      final result = await useCase.execute(
        dayObjectiveIds: dayObjectiveIds,
      );

      if (!mounted) return;

      result.when(
        success: (sprint) {
          context.showSnackBar(context.l10n.sprintCreated);
          setState(() {
            _existingSprint = sprint;
          });
        },
        failure: (error) =>
            context.showSnackBar(error.message, isError: true),
      );
    }
  }
}

class _DayChip extends StatelessWidget {
  final int dayIndex;
  final String localeName;
  final bool isSelected;
  final bool isToday;
  final bool hasObjectives;
  final VoidCallback onTap;

  const _DayChip({
    required this.dayIndex,
    required this.localeName,
    required this.isSelected,
    required this.isToday,
    required this.hasObjectives,
    required this.onTap,
  });

  String _letter() {
    final ref = DateTime(2024, 1, 1).add(Duration(days: dayIndex));
    return DateFormat('EEEEE', localeName).format(ref).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final bg =
        isSelected ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = isSelected ? scheme.onPrimary : scheme.onSurface;

    return SizedBox(
      height: 52,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday && !isSelected
                    ? scheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  _letter(),
                  style: context.textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasObjectives)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? scheme.onPrimary : scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
