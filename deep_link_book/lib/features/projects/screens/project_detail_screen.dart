import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/deeplink/deeplink_launcher.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../deeplinks/data/deeplink_repository.dart';
import '../../deeplinks/developer_tools/developer_tools_view.dart';
import '../../deeplinks/providers/deeplink_providers.dart';
import '../../deeplinks/validation/deeplink_validator.dart';
import '../../deeplinks/widgets/deeplink_list_item.dart';
import '../../environments/providers/environment_providers.dart';
import '../../history/data/history_repository.dart';
import '../data/project_repository.dart';
import '../providers/project_providers.dart';
import '../widgets/project_dialog.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final int? projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  static const _invalidHistoryMessage = 'Invalid deeplink URL.';
  static const _noHandlerMessage = 'No app can open this deeplink.';
  static const _unableToOpenMessage = 'Unable to open deeplink.';

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _processingFavoriteIds = <int>{};
  final _openingDeeplinkIds = <int>{};
  int? _processingDeeplinkId;
  var _searchQuery = '';
  var _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;
    final projects = ref.watch(projectsProvider);
    final deeplinks = ref.watch(allDeeplinksProvider);

    if (projectId == null) {
      return const Scaffold(
        appBar: _ProjectDetailFallbackAppBar(),
        body: Center(
          child: AppEmptyState(
            icon: Icons.folder_off,
            title: 'Project not found',
            description: 'Return to Projects and try again.',
          ),
        ),
      );
    }

    final project = _findProject(projects.value ?? const [], projectId);
    final projectDeeplinks = _buildProjectDeeplinks(
      deeplinks.value ?? const [],
      projectId,
      _searchQuery,
    );
    final isLoading =
        (projects.isLoading && !projects.hasValue) ||
        (deeplinks.isLoading && !deeplinks.hasValue);
    final hasError = projects.hasError || deeplinks.hasError;

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search project deeplinks',
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: _updateSearchQuery,
                )
              : Text(project?.name ?? 'Project'),
          actions: [
            if (_isSearching)
              IconButton(
                tooltip: 'Clear search',
                onPressed: _closeSearch,
                icon: const Icon(Icons.close),
              )
            else ...[
              IconButton(
                tooltip: 'Search project deeplinks',
                onPressed: _startSearch,
                icon: const Icon(Icons.search),
              ),
              if (project != null)
                IconButton(
                  tooltip: 'Edit ${project.name}',
                  onPressed: () => _showEditProjectDialog(project),
                  icon: const Icon(Icons.edit),
                ),
              if (project != null)
                PopupMenuButton<_ProjectDetailAction>(
                  tooltip: 'More project actions',
                  onSelected: (action) {
                    switch (action) {
                      case _ProjectDetailAction.delete:
                        _deleteProject(project, projects.value?.length ?? 0);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ProjectDetailAction.delete,
                      child: Text(
                        'Delete Project',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
        body: _buildBody(
          isLoading: isLoading,
          hasError: hasError,
          project: project,
          projectDeeplinks: projectDeeplinks,
          deeplinkCount: _countProjectDeeplinks(
            deeplinks.value ?? const [],
            projectId,
          ),
        ),
        floatingActionButton: project == null
            ? null
            : FloatingActionButton(
                tooltip: 'Add deeplink to ${project.name}',
                onPressed: () => _addDeeplinkToProject(project),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required bool hasError,
    required Project? project,
    required List<Deeplink> projectDeeplinks,
    required int deeplinkCount,
  }) {
    if (isLoading) {
      return const AppLoadingState();
    }

    if (hasError) {
      return Center(
        child: AppErrorState(
          title: 'Unable to load project',
          description: 'Please try again later.',
          onRetry: () {
            ref.invalidate(projectsProvider);
            ref.invalidate(allDeeplinksProvider);
          },
        ),
      );
    }

    if (project == null) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.folder_off,
          title: 'Project not found',
          description: 'Return to Projects and try again.',
        ),
      );
    }

    final hasSearchQuery = _searchQuery.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _ProjectDetailHeader(project: project, deeplinkCount: deeplinkCount),
        const SizedBox(height: AppSpacing.lg),
        Text('Deeplinks', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (projectDeeplinks.isEmpty)
          _ProjectDetailEmptyDeeplinks(
            icon: hasSearchQuery ? Icons.search_off : Icons.link_off,
            title: hasSearchQuery
                ? 'No results for "$_searchQuery"'
                : 'No deeplinks yet',
            description: hasSearchQuery
                ? 'Try a different search term.'
                : 'Add a deeplink to this project.',
          )
        else
          for (var index = 0; index < projectDeeplinks.length; index++) ...[
            DeeplinkListItem(
              deeplink: projectDeeplinks[index],
              isProcessing: _processingDeeplinkId == projectDeeplinks[index].id,
              isFavoriteProcessing: _processingFavoriteIds.contains(
                projectDeeplinks[index].id,
              ),
              isOpening: _openingDeeplinkIds.contains(
                projectDeeplinks[index].id,
              ),
              onTap: () => _openEditScreen(projectDeeplinks[index]),
              onOpen: () => _openDeeplink(projectDeeplinks[index]),
              onFavoriteTap: () => _toggleFavorite(projectDeeplinks[index]),
              onEdit: () => _openEditScreen(projectDeeplinks[index]),
              onCopy: () => _copyDeeplinkUrl(projectDeeplinks[index].url),
              onDeveloperTools: () =>
                  _showDeveloperTools(projectDeeplinks[index].url),
              onDuplicate: () => _duplicateDeeplink(projectDeeplinks[index]),
              onDelete: () =>
                  _confirmAndDeleteDeeplink(projectDeeplinks[index]),
            ),
            if (index != projectDeeplinks.length - 1) const Divider(height: 1),
          ],
      ],
    );
  }

  Project? _findProject(List<Project> projects, int projectId) {
    for (final project in projects) {
      if (project.id == projectId) {
        return project;
      }
    }

    return null;
  }

  List<Deeplink> _buildProjectDeeplinks(
    List<Deeplink> deeplinks,
    int projectId,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    final projectDeeplinks = deeplinks.where((deeplink) {
      if (deeplink.projectId != projectId) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return deeplink.name.toLowerCase().contains(normalizedQuery) ||
          deeplink.url.toLowerCase().contains(normalizedQuery);
    }).toList();

    projectDeeplinks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return projectDeeplinks;
  }

  int _countProjectDeeplinks(List<Deeplink> deeplinks, int projectId) {
    var count = 0;

    for (final deeplink in deeplinks) {
      if (deeplink.projectId == projectId) {
        count++;
      }
    }

    return count;
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
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
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  Future<void> _showEditProjectDialog(Project project) async {
    final saved = await showProjectDialog(context: context, project: project);

    if (!mounted || !saved) {
      return;
    }

    _showSnackBar('Project saved.');
  }

  Future<void> _deleteProject(Project project, int projectCount) async {
    if (projectCount <= 1) {
      _showSnackBar('At least one project is required.');
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete project?',
      message: 'Only empty projects can be deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!mounted || !confirmed) {
      return;
    }

    final deleted = await ref
        .read(projectRepositoryProvider)
        .deleteProject(project.id);

    if (!mounted) {
      return;
    }

    if (!deleted) {
      _showSnackBar(
        'This project cannot be deleted while it still contains saved data.',
      );
      return;
    }

    final currentProjectId = ref.read(currentProjectIdProvider);
    if (currentProjectId == project.id) {
      ref.read(currentProjectIdProvider.notifier).select(null);
      ref.read(currentEnvironmentIdProvider.notifier).select(null);
    }

    _showSnackBar('Project deleted.');
    context.goNamed(AppRoute.projects.name);
  }

  void _addDeeplinkToProject(Project project) {
    ref.read(currentProjectIdProvider.notifier).select(project.id);
    ref.read(currentEnvironmentIdProvider.notifier).select(null);
    context.pushNamed(AppRoute.addDeeplink.name);
  }

  void _openEditScreen(Deeplink deeplink) {
    context.pushNamed(
      AppRoute.editDeeplink.name,
      pathParameters: {'id': deeplink.id.toString()},
    );
  }

  Future<void> _copyDeeplinkUrl(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));

      if (!mounted) {
        return;
      }

      _showSnackBar('Deeplink copied.');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to copy deeplink.');
    }
  }

  Future<void> _showDeveloperTools(String url) {
    return showDeveloperToolsSheet(context: context, url: url.trim());
  }

  Future<void> _openDeeplink(Deeplink deeplink) async {
    if (_openingDeeplinkIds.contains(deeplink.id)) {
      return;
    }

    setState(() {
      _openingDeeplinkIds.add(deeplink.id);
    });

    try {
      final trimmedUrl = deeplink.url.trim();
      final validationError = DeeplinkValidator.validateUrl(trimmedUrl);
      final historyRepository = ref.read(historyRepositoryProvider);

      if (validationError != null) {
        await _recordOpenHistory(
          historyRepository,
          deeplink,
          isSuccess: false,
          errorMessage: _invalidHistoryMessage,
          showHistoryFailureMessage: false,
        );

        if (!mounted) {
          return;
        }

        _showSnackBar(validationError);
        return;
      }

      final launcher = ref.read(deeplinkLauncherProvider);
      final repository = ref.read(deeplinkRepositoryProvider);
      final launched = await launcher.open(Uri.parse(trimmedUrl));

      if (!mounted) {
        return;
      }

      if (!launched) {
        await _recordOpenHistory(
          historyRepository,
          deeplink,
          isSuccess: false,
          errorMessage: _noHandlerMessage,
          showHistoryFailureMessage: false,
        );

        if (!mounted) {
          return;
        }

        _showSnackBar(_noHandlerMessage);
        return;
      }

      await _recordOpenHistory(
        historyRepository,
        deeplink,
        isSuccess: true,
        showHistoryFailureMessage: true,
      );
      await _recordSuccessfulOpen(repository, deeplink.id);
    } catch (_) {
      final historyRepository = ref.read(historyRepositoryProvider);
      await _recordOpenHistory(
        historyRepository,
        deeplink,
        isSuccess: false,
        errorMessage: _unableToOpenMessage,
        showHistoryFailureMessage: false,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(_unableToOpenMessage);
    } finally {
      if (mounted) {
        setState(() {
          _openingDeeplinkIds.remove(deeplink.id);
        });
      }
    }
  }

  Future<void> _recordOpenHistory(
    HistoryRepository repository,
    Deeplink deeplink, {
    required bool isSuccess,
    String? errorMessage,
    required bool showHistoryFailureMessage,
  }) async {
    try {
      await repository.createHistory(
        deeplinkId: deeplink.id,
        name: deeplink.name,
        url: deeplink.url,
        isSuccess: isSuccess,
        errorMessage: errorMessage,
      );
    } catch (_) {
      if (!mounted || !showHistoryFailureMessage) {
        return;
      }

      _showSnackBar('Deeplink opened, but history could not be saved.');
    }
  }

  Future<void> _recordSuccessfulOpen(
    DeeplinkRepository repository,
    int deeplinkId,
  ) async {
    try {
      final recorded = await repository.recordDeeplinkOpened(deeplinkId);

      if (!mounted) {
        return;
      }

      if (!recorded) {
        _showSnackBar('Deeplink opened, but its usage could not be updated.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Deeplink opened, but usage could not be saved.');
    }
  }

  Future<void> _toggleFavorite(Deeplink deeplink) async {
    if (_processingFavoriteIds.contains(deeplink.id)) {
      return;
    }

    setState(() {
      _processingFavoriteIds.add(deeplink.id);
    });

    try {
      final updated = await ref
          .read(deeplinkRepositoryProvider)
          .toggleFavorite(deeplink.id);

      if (!mounted) {
        return;
      }

      if (!updated) {
        _showSnackBar('This deeplink no longer exists.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to update favorite.');
    } finally {
      if (mounted) {
        setState(() {
          _processingFavoriteIds.remove(deeplink.id);
        });
      }
    }
  }

  Future<void> _duplicateDeeplink(Deeplink deeplink) async {
    if (_processingDeeplinkId != null) {
      return;
    }

    setState(() {
      _processingDeeplinkId = deeplink.id;
    });

    try {
      final duplicatedId = await ref
          .read(deeplinkRepositoryProvider)
          .duplicateDeeplink(deeplink.id);

      if (!mounted) {
        return;
      }

      if (duplicatedId == null) {
        _showSnackBar('This deeplink no longer exists.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to duplicate deeplink.');
    } finally {
      if (mounted) {
        setState(() {
          _processingDeeplinkId = null;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteDeeplink(Deeplink deeplink) async {
    if (_processingDeeplinkId != null) {
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete deeplink?',
      message: 'This deeplink will be permanently removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _processingDeeplinkId = deeplink.id;
    });

    try {
      final deleted = await ref
          .read(deeplinkRepositoryProvider)
          .deleteDeeplink(deeplink.id);

      if (!mounted) {
        return;
      }

      if (!deleted) {
        _showSnackBar('This deeplink no longer exists.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to delete deeplink.');
    } finally {
      if (mounted) {
        setState(() {
          _processingDeeplinkId = null;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProjectDetailFallbackAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProjectDetailFallbackAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Project'));
  }
}

class _ProjectDetailHeader extends StatelessWidget {
  const _ProjectDetailHeader({
    required this.project,
    required this.deeplinkCount,
  });

  final Project project;
  final int deeplinkCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final description = project.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(project.name, style: textTheme.headlineSmall),
        if (description != null && description.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          _deeplinkCountLabel,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String get _deeplinkCountLabel {
    if (deeplinkCount == 1) {
      return '1 deeplink';
    }

    return '$deeplinkCount deeplinks';
  }
}

class _ProjectDetailEmptyDeeplinks extends StatelessWidget {
  const _ProjectDetailEmptyDeeplinks({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

enum _ProjectDetailAction { delete }
