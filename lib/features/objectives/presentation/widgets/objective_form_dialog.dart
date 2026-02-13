import 'package:flutter/material.dart';
import 'package:dinovigilo/features/objectives/domain/entities/objective.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';

class ObjectiveFormDialog extends StatefulWidget {
  /// If provided, the dialog edits this objective. Otherwise it creates a new one.
  final Objective? objective;

  const ObjectiveFormDialog({super.key, this.objective});

  @override
  State<ObjectiveFormDialog> createState() => _ObjectiveFormDialogState();
}

class _ObjectiveFormDialogState extends State<ObjectiveFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.objective != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.objective?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.objective?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isEditing
            ? context.l10n.editObjective
            : context.l10n.createObjective,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.objectiveTitle,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.titleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.objectiveDescription,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(context.l10n.save),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    Navigator.of(context).pop(
      ObjectiveFormResult(
        title: title,
        description: description.isEmpty ? null : description,
      ),
    );
  }
}

class ObjectiveFormResult {
  final String title;
  final String? description;

  const ObjectiveFormResult({required this.title, this.description});
}
