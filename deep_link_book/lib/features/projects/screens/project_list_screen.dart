import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_root_top_bar.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../deeplinks/providers/deeplink_providers.dart';
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
        ),
        body: projects.when(
          loading: () => const AppLoadingState(),
          error: (error, stackTrace) => Center(
            child: AppErrorState(
              title: 'Unable to load projects',
              description: 'Please try again later.',
              onRetry: () {
                ref.invalidate(projectsProvider);
                ref.invalidate(allDeeplinksProvider);
              },
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
    FocusScope.of(context).unfocus();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _openSettings() {
    context.pushNamed(AppRoute.settings.name);
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
}
