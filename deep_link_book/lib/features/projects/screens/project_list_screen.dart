import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_brand_icon.dart';
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
          title: 'Deep Link Book',
          searchQuery: _searchQuery,
          isSearching: _isSearching,
          onSearchPressed: _startSearch,
          onSearchQueryChanged: _updateSearchQuery,
          onSearchClose: _closeSearch,
          onSettingsPressed: _openSettings,
          eyebrow: 'Dev Suite',
          leading: const AppBrandIcon(),
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

            final itemCount = visibleProjects.length + (hasSearchQuery ? 0 : 1);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _ProjectsPageHeader(projectCount: projects.length),
                  ),
                ),
                if (visibleProjects.isEmpty && hasSearchQuery)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppEmptyState(
                        icon: Icons.search_off,
                        title: 'No projects found for "$_searchQuery"',
                        description: 'Try a different search term.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            mainAxisExtent: 180,
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
                            pathParameters: {
                              'projectId': project.id.toString(),
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
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

class _ProjectsPageHeader extends StatelessWidget {
  const _ProjectsPageHeader({required this.projectCount});

  final int projectCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final projectLabel = projectCount == 1 ? 'project' : 'projects';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projects',
          style: textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$projectCount active workspace $projectLabel',
          style: textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
