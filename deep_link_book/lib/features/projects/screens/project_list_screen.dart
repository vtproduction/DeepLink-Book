import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_root_top_bar.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../deeplinks/providers/deeplink_providers.dart';
import '../../environments/providers/environment_providers.dart';
import '../../import_export/import_export_file_service.dart';
import '../../import_export/project_importer.dart';
import '../providers/project_providers.dart';
import '../widgets/new_project_grid_item.dart';
import '../widgets/project_dialog.dart';
import '../widgets/project_grid_item.dart';

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
    final deeplinks = ref.watch(allDeeplinksProvider);

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
            final deeplinkCounts = _buildProjectDeeplinkCounts(
              deeplinks.value ?? const [],
            );
            final visibleProjects = _buildVisibleProjects(
              projects,
              _searchQuery,
            );
            final hasSearchQuery = _searchQuery.trim().isNotEmpty;

            if (visibleProjects.isEmpty) {
              if (hasSearchQuery) {
                return Center(
                  child: AppEmptyState(
                    icon: Icons.search_off,
                    title: 'No projects found for "$_searchQuery"',
                    description: 'Try a different search term.',
                  ),
                );
              }
            }

            final itemCount = visibleProjects.length + (hasSearchQuery ? 0 : 1);

            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (!hasSearchQuery && index == 0) {
                  return NewProjectGridItem(
                    onTap: () => _showProjectDialog(context),
                  );
                }

                final projectIndex = hasSearchQuery ? index : index - 1;
                final project = visibleProjects[projectIndex];

                return ProjectGridItem(
                  project: project,
                  deeplinkCount: deeplinkCounts[project.id] ?? 0,
                  onTap: () => context.pushNamed(
                    AppRoute.projectDetail.name,
                    pathParameters: {'projectId': project.id.toString()},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Map<int, int> _buildProjectDeeplinkCounts(List<Deeplink> deeplinks) {
    final counts = <int, int>{};

    for (final deeplink in deeplinks) {
      final projectId = deeplink.projectId;

      if (projectId == null) {
        continue;
      }

      counts.update(projectId, (count) => count + 1, ifAbsent: () => 1);
    }

    return counts;
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
    BuildContext context, [
    Project? project,
  ]) async {
    final saved = await showProjectDialog(context: context, project: project);

    if (saved != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(project == null ? 'Project created.' : 'Project saved.'),
      ),
    );
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
