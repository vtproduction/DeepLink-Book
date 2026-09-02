import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';

class DeeplinkOrganizationFields extends StatelessWidget {
  const DeeplinkOrganizationFields({
    super.key,
    required this.projects,
    required this.selectedProjectId,
    required this.onProjectChanged,
    required this.enabled,
  });

  final AsyncValue<List<Project>> projects;
  final int? selectedProjectId;
  final ValueChanged<int?> onProjectChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        projects.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => const Text('Unable to load projects'),
          data: (projects) {
            return DropdownButtonFormField<int>(
              key: ValueKey('project-$selectedProjectId'),
              initialValue: selectedProjectId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Project'),
              items: projects.map((project) {
                return DropdownMenuItem(
                  value: project.id,
                  child: Text(project.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: enabled ? onProjectChanged : null,
              validator: (value) {
                if (value == null) {
                  return 'Select a project.';
                }

                return null;
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
