import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../environments/providers/environment_providers.dart';
import '../data/project_repository.dart';
import '../providers/project_providers.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load projects',
            description: 'Please try again later.',
          ),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.folder_off,
                title: 'No projects',
                description: 'Create a project to organize deeplinks.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(project.name),
                subtitle: Text(project.description ?? 'No description'),
                trailing: PopupMenuButton<_ProjectAction>(
                  tooltip: 'Project actions for ${project.name}',
                  onSelected: (action) async {
                    switch (action) {
                      case _ProjectAction.environments:
                        context.pushNamed(
                          AppRoute.environments.name,
                          pathParameters: {'projectId': project.id.toString()},
                        );
                      case _ProjectAction.edit:
                        await _showProjectDialog(context, ref, project);
                      case _ProjectAction.delete:
                        await _deleteProject(
                          context,
                          ref,
                          project,
                          projects.length,
                        );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ProjectAction.environments,
                      child: Text('Manage environments'),
                    ),
                    PopupMenuItem(
                      value: _ProjectAction.edit,
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: _ProjectAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add project',
        onPressed: () => _showProjectDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showProjectDialog(
    BuildContext context,
    WidgetRef ref, [
    Project? project,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _ProjectDialog(project: project),
    );

    if (saved != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(project == null ? 'Project created.' : 'Project saved.'),
      ),
    );
  }

  Future<void> _deleteProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
    int projectCount,
  ) async {
    if (projectCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one project is required.')),
      );
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete project?',
      message: 'Only empty projects can be deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!context.mounted || !confirmed) {
      return;
    }

    final deleted = await ref
        .read(projectRepositoryProvider)
        .deleteProject(project.id);

    if (!context.mounted) {
      return;
    }

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This project cannot be deleted while it contains deeplinks or environments.',
          ),
        ),
      );
      return;
    }

    final currentProjectId = ref.read(currentProjectIdProvider);
    if (currentProjectId == project.id) {
      ref.read(currentProjectIdProvider.notifier).select(null);
      ref.read(currentEnvironmentIdProvider.notifier).select(null);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Project deleted.')));
  }
}

class _ProjectDialog extends ConsumerStatefulWidget {
  const _ProjectDialog({this.project});

  final Project? project;

  @override
  ConsumerState<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends ConsumerState<_ProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
              enabled: !_isSaving,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a project name.';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional',
              ),
              maxLines: 3,
              enabled: !_isSaving,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => context.pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(widget.project == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final repository = ref.read(projectRepositoryProvider);

    try {
      final project = widget.project;

      if (project == null) {
        await repository.createProject(
          name: name,
          description: description.isEmpty ? null : description,
        );
      } else {
        await repository.updateProject(
          id: project.id,
          name: name,
          description: description.isEmpty ? null : description,
        );
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to save project.')));
    }
  }
}

enum _ProjectAction { environments, edit, delete }
