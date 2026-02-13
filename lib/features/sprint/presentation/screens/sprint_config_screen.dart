import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/features/objectives/presentation/providers/objective_providers.dart';
import 'package:dinovigilo/features/objectives/presentation/screens/objectives_screen.dart';
import 'package:dinovigilo/features/sprint/domain/entities/sprint.dart';
import 'package:dinovigilo/features/sprint/presentation/providers/sprint_providers.dart';
import 'package:dinovigilo/features/sprint/presentation/widgets/day_selector.dart';
import 'package:dinovigilo/features/sprint/presentation/widgets/objective_assignment.dart';
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
  DateTime _startDate = DateTime.now();
  int? _expandedDay;
  bool _loaded = false;
  Sprint? _existingSprint;

  final Map<int, Set<String>> _dayObjectives = {};

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );
  }

  void _loadFromSprint(Sprint sprint) {
    _existingSprint = sprint;
    _startDate = sprint.startDate;
    _dayObjectives.clear();
    for (final mapping in sprint.dayMappings) {
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
              // Load existing sprint data once
              if (!_loaded && sprint != null) {
                _loadFromSprint(sprint);
              } else if (!_loaded) {
                _loaded = true;
              }

              return _buildConfigForm(context, objectives, sprint);
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

  Widget _buildConfigForm(
    BuildContext context,
    List<Objective> objectives,
    Sprint? activeSprint,
  ) {
    final dateFormat = DateFormat.yMMMd();

    return Column(
      children: [
        // Start date picker
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: InkWell(
              onTap: () => _pickStartDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.sprintStartDate,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            dateFormat.format(_startDate),
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            context.l10n.sprintEndsOn(
                              dateFormat.format(
                                _startDate.add(const Duration(days: 14)),
                              ),
                            ),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Day list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 14,
            itemBuilder: (context, dayIndex) {
              final dayDate = _startDate.add(Duration(days: dayIndex));
              final isExpanded = _expandedDay == dayIndex;
              final selectedIds = _dayObjectives[dayIndex] ?? {};

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  children: [
                    DaySelector(
                      dayIndex: dayIndex,
                      date: dayDate,
                      objectiveCount: selectedIds.length,
                      isExpanded: isExpanded,
                      onTap: () {
                        setState(() {
                          _expandedDay = isExpanded ? null : dayIndex;
                        });
                      },
                    ),
                    if (isExpanded)
                      ObjectiveAssignment(
                        dayIndex: dayIndex,
                        allObjectives: objectives,
                        selectedObjectiveIds: selectedIds,
                        onToggle: (objectiveId) {
                          setState(() {
                            final set = _dayObjectives.putIfAbsent(
                              dayIndex,
                              () => {},
                            );
                            if (set.contains(objectiveId)) {
                              set.remove(objectiveId);
                            } else {
                              set.add(objectiveId);
                            }
                          });
                        },
                        onApplyToAll: () {
                          setState(() {
                            final currentSet =
                                _dayObjectives[dayIndex] ?? {};
                            for (var i = 0; i < 14; i++) {
                              _dayObjectives[i] = Set.from(currentSet);
                            }
                          });
                        },
                        onCopyFromPrevious: dayIndex > 0
                            ? () {
                                setState(() {
                                  final previousSet =
                                      _dayObjectives[dayIndex - 1] ?? {};
                                  _dayObjectives[dayIndex] =
                                      Set.from(previousSet);
                                });
                              }
                            : null,
                        onClear: () {
                          setState(() {
                            _dayObjectives[dayIndex]?.clear();
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Save button
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

  bool _hasAnyObjective() {
    return _dayObjectives.values.any((set) => set.isNotEmpty);
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: context.l10n.selectStartDate,
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
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
        sprint: _existingSprint!.copyWith(startDate: _startDate),
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
        startDate: _startDate,
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
