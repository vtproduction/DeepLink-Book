import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_root_top_bar.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../environments/providers/environment_providers.dart';
import '../../import_export/import_export_file_service.dart';
import '../../import_export/project_exporter.dart';
import '../../import_export/project_importer.dart';
import '../data/project_repository.dart';
import '../providers/project_providers.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  var _searchQuery = '';
  var _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        appBar: AppRootTopBar(
          title: 'Projects',
          searchQuery: _searchQuery,
          isSearching: _isSearching,
          onSearchPressed: _startSearch,
          onSearchQueryChanged: _updateSearchQuery,
          onSearchClose: _closeSearch,
          onSettingsPressed: _openSettings,
          actions: [
            IconButton(
              tooltip: 'Import project',
              onPressed: () => _importProject(context, ref),
              icon: const Icon(Icons.upload_file),
            ),
          ],
        ),
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
            final visibleProjects = _buildVisibleProjects(
              projects,
              _searchQuery,
            );
            final hasSearchQuery = _searchQuery.trim().isNotEmpty;

            if (visibleProjects.isEmpty) {
              return Center(
                child: AppEmptyState(
                  icon: hasSearchQuery ? Icons.search_off : Icons.folder_off,
                  title: hasSearchQuery
                      ? 'No matching projects'
                      : 'No projects',
                  description: hasSearchQuery
                      ? 'Try a different search term.'
                      : 'Create a project to organize deeplinks.',
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: visibleProjects.length,
              itemBuilder: (context, index) {
                final project = visibleProjects[index];

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
                            pathParameters: {
                              'projectId': project.id.toString(),
                            },
                          );
                        case _ProjectAction.export:
                          await _exportProject(context, ref, project);
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
                        value: _ProjectAction.export,
                        child: Text('Export'),
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
      ),
    );
  }

  List<Project> _buildVisibleProjects(List<Project> projects, String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return projects;
    }

    return projects.where((project) {
      final description = project.description;

      return project.name.toLowerCase().contains(normalizedQuery) ||
          (description?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _closeSearch() {
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _openSettings() {
    context.pushNamed(AppRoute.settings.name);
  }

  Future<void> _exportProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    try {
      final exportData = await ref
          .read(projectExporterProvider)
          .exportProject(project.id);

      if (!context.mounted) {
        return;
      }

      if (exportData == null) {
        _showSnackBar(context, 'Project no longer exists.');
        return;
      }

      final saved = await ref
          .read(importExportFileServiceProvider)
          .saveExportFile(
            fileName: buildProjectExportFileName(project.name),
            content: exportData.toPrettyJson(),
          );

      if (!context.mounted) {
        return;
      }

      if (saved) {
        _showSnackBar(context, 'Exported "${project.name}".');
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      _showSnackBar(context, 'Unable to export project.');
    }
  }

  Future<void> _importProject(BuildContext context, WidgetRef ref) async {
    try {
      final content = await ref
          .read(importExportFileServiceProvider)
          .pickImportFileContent();

      if (content == null || !context.mounted) {
        return;
      }

      final importer = ref.read(projectImporterProvider);
      final preview = importer.previewImport(content);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ImportPreviewDialog(preview: preview),
      );

      if (confirmed != true || !context.mounted) {
        return;
      }

      final result = await importer.importProject(content);

      if (!context.mounted) {
        return;
      }

      ref.read(currentProjectIdProvider.notifier).select(result.projectId);
      ref.read(currentEnvironmentIdProvider.notifier).select(null);
      _showSnackBar(context, 'Imported "${result.projectName}".');
    } on ProjectImportException catch (error) {
      if (!context.mounted) {
        return;
      }

      _showSnackBar(context, 'Import failed: ${error.message}');
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      _showSnackBar(context, 'Unable to import project.');
    }
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ImportPreviewDialog extends StatelessWidget {
  const _ImportPreviewDialog({required this.preview});

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
          Text('${preview.environmentCount} environments'),
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

enum _ProjectAction { environments, export, edit, delete }
