import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/widgets/empty_state.dart';
import 'package:dinovigilo/shared/widgets/error_display.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';
import 'package:dinovigilo/features/objectives/presentation/providers/objective_providers.dart';
import 'package:dinovigilo/features/objectives/presentation/widgets/objective_card.dart';
import 'package:dinovigilo/features/objectives/presentation/widgets/objective_form_dialog.dart';

class ObjectivesScreen extends ConsumerWidget {
  const ObjectivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectivesAsync = ref.watch(objectivesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.objectives),
      ),
      body: objectivesAsync.when(
        data: (objectives) {
          if (objectives.isEmpty) {
            return EmptyState(
              message: context.l10n.noObjectivesYet,
              icon: Icons.checklist,
              actionLabel: context.l10n.createObjective,
              onAction: () => _showCreateDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: objectives.length,
            itemBuilder: (context, index) {
              final objective = objectives[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ObjectiveCard(
                  objective: objective,
                  onEdit: () => _showEditDialog(context, ref, objective),
                  onDelete: () => _handleDelete(context, ref, objective.id),
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(objectivesStreamProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<ObjectiveFormResult>(
      context: context,
      builder: (_) => const ObjectiveFormDialog(),
    );

    if (result == null) return;

    final useCase = ref.read(createObjectiveUseCaseProvider);
    final createResult = await useCase.execute(
      title: result.title,
      description: result.description,
    );

    if (!context.mounted) return;

    createResult.when(
      success: (_) => context.showSnackBar(context.l10n.objectiveCreated),
      failure: (error) => context.showSnackBar(error.message, isError: true),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Objective objective,
  ) async {
    final result = await showDialog<ObjectiveFormResult>(
      context: context,
      builder: (_) => ObjectiveFormDialog(objective: objective),
    );

    if (result == null) return;

    final useCase = ref.read(updateObjectiveUseCaseProvider);
    final updateResult = await useCase.execute(
      objective.copyWith(
        title: result.title,
        description: result.description,
      ),
    );

    if (!context.mounted) return;

    updateResult.when(
      success: (_) => context.showSnackBar(context.l10n.objectiveUpdated),
      failure: (error) => context.showSnackBar(error.message, isError: true),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final useCase = ref.read(deleteObjectiveUseCaseProvider);
    final deleteResult = await useCase.execute(id);

    if (!context.mounted) return;

    deleteResult.when(
      success: (_) => context.showSnackBar(context.l10n.objectiveDeleted),
      failure: (error) => context.showSnackBar(error.message, isError: true),
    );
  }
}
