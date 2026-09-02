import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../project_importer.dart';

class ImportProjectPreviewDialog extends StatelessWidget {
  const ImportProjectPreviewDialog({super.key, required this.preview});

  final ProjectImportPreview preview;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Project'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.projectName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${preview.deeplinkCount} deeplinks'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: const Text('Import'),
        ),
      ],
    );
  }
}
