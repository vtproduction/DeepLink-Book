import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';

class DeeplinkOrganizationFields extends StatelessWidget {
  const DeeplinkOrganizationFields({
    super.key,
    required this.projects,
    required this.environments,
    required this.selectedProjectId,
    required this.selectedEnvironmentId,
    required this.onProjectChanged,
    required this.onEnvironmentChanged,
    required this.enabled,
  });

  final AsyncValue<List<Project>> projects;
  final AsyncValue<List<Environment>> environments;
  final int? selectedProjectId;
  final int? selectedEnvironmentId;
  final ValueChanged<int?> onProjectChanged;
  final ValueChanged<int?> onEnvironmentChanged;
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
        environments.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) =>
              const Text('Unable to load environments'),
          data: (environments) {
            return DropdownButtonFormField<int?>(
              key: ValueKey('environment-$selectedEnvironmentId'),
              initialValue: selectedEnvironmentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Environment'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All environments'),
                ),
                ...environments.map((environment) {
                  return DropdownMenuItem<int?>(
                    value: environment.id,
                    child: Text(
                      environment.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: enabled ? onEnvironmentChanged : null,
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
