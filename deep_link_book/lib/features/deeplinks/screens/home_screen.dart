import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_root_top_bar.dart';
import '../../../core/deeplink/deeplink_launcher.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../data/deeplink_repository.dart';
import '../developer_tools/deeplink_command_builder.dart';
import '../developer_tools/developer_tools_view.dart';
import '../providers/deeplink_providers.dart';
import '../validation/deeplink_validator.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/deeplink_list_item.dart';
import '../widgets/quick_link_card.dart';
import '../../environments/providers/environment_providers.dart';
import '../../history/data/history_repository.dart';
import '../../history/providers/history_providers.dart';
import '../../projects/providers/project_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.title = 'Home',
    this.favoritesOnly = false,
  });

  final String title;
  final bool favoritesOnly;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const _invalidHistoryMessage = 'Invalid deeplink URL.';
  static const _noHandlerMessage = 'No app can open this deeplink.';
  static const _unableToOpenMessage = 'Unable to open deeplink.';
  static const _clipboardHistoryName = 'Clipboard Quick Link';

  int? _processingDeeplinkId;
  final _processingFavoriteIds = <int>{};
  final _openingDeeplinkIds = <int>{};
  final _openingHistoryIds = <int>{};
  var _searchQuery = '';
  var _isSearching = false;
  var _sortOption = DeeplinkSortOption.recentlyUpdated;
  String? _clipboardQuickLinkUrl;
  var _isOpeningClipboardQuickLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.favoritesOnly) {
        _refreshClipboardQuickLink();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !widget.favoritesOnly) {
      _refreshClipboardQuickLink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deeplinks = ref.watch(allDeeplinksProvider);
    final projects = ref.watch(projectsProvider);
    final environments = ref.watch(environmentsForCurrentProjectProvider);
    final recentHistory = ref.watch(recentHistoryProvider(3));

    _syncCurrentProject(projects);
    _syncCurrentEnvironment(environments);

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        backgroundColor: widget.favoritesOnly ? null : const Color(0xFFF3F6FA),
        appBar: AppRootTopBar(
          title: widget.favoritesOnly ? widget.title : 'Deep Link Book',
          searchQuery: _searchQuery,
          isSearching: _isSearching,
          onSearchPressed: _startSearch,
          onSearchQueryChanged: _updateSearchQuery,
          onSearchClose: _closeSearch,
          onSettingsPressed: _openSettings,
          eyebrow: widget.favoritesOnly ? null : 'Dev Suite',
          leading: widget.favoritesOnly ? null : const _HomeBrandIcon(),
        ),
        body: widget.favoritesOnly
            ? _buildDeeplinkListBody(deeplinks)
            : _buildHomeBody(deeplinks, projects, recentHistory),
        floatingActionButton: widget.favoritesOnly
            ? null
            : FloatingActionButton(
                backgroundColor: const Color(0xFF22D3EE),
                foregroundColor: const Color(0xFF020617),
                tooltip: 'Add deeplink',
                onPressed: () => context.pushNamed(AppRoute.addDeeplink.name),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Widget _buildDeeplinkListBody(AsyncValue<List<Deeplink>> deeplinks) {
    return deeplinks.when(
      loading: () => const AppLoadingState(),
      error: (error, stackTrace) => Center(
        child: AppErrorState(
          title: 'Unable to load deeplinks',
          description: 'Please try again later.',
          onRetry: () => ref.invalidate(allDeeplinksProvider),
        ),
      ),
      data: (deeplinks) {
        final visibleDeeplinks = _buildVisibleDeeplinks(
          deeplinks,
          _searchQuery,
          favoritesOnly: widget.favoritesOnly,
          sortOption: _sortOption,
        );
        final hasSearchQuery = _searchQuery.trim().isNotEmpty;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PopupMenuButton<DeeplinkSortOption>(
                    tooltip: 'Sort deeplinks',
                    initialValue: _sortOption,
                    onSelected: (sortOption) {
                      setState(() {
                        _sortOption = sortOption;
                      });
                    },
                    itemBuilder: (context) {
                      return DeeplinkSortOption.values.map((sortOption) {
                        return PopupMenuItem(
                          value: sortOption,
                          child: Text(sortOption.label),
                        );
                      }).toList();
                    },
                    child: InputChip(
                      avatar: const Icon(Icons.sort),
                      label: Text(_sortOption.label),
                    ),
                  ),
                ],
              ),
            ),
            if (visibleDeeplinks.isEmpty)
              Expanded(
                child: Center(
                  child: _emptyStateForVisibleDeeplinks(
                    hasSearchQuery: hasSearchQuery,
                    query: _searchQuery,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: visibleDeeplinks.length,
                  itemBuilder: (context, index) {
                    final deeplink = visibleDeeplinks[index];

                    return DeeplinkListItem(
                      deeplink: deeplink,
                      isProcessing: _processingDeeplinkId == deeplink.id,
                      isFavoriteProcessing: _processingFavoriteIds.contains(
                        deeplink.id,
                      ),
                      isOpening: _openingDeeplinkIds.contains(deeplink.id),
                      onTap: () => _openEditScreen(deeplink),
                      onOpen: () => _openDeeplink(deeplink),
                      onFavoriteTap: () => _toggleFavorite(deeplink),
                      onEdit: () => _openEditScreen(deeplink),
                      onCopy: () => _copyDeeplinkUrl(deeplink.url),
                      onDeveloperTools: () => _showDeveloperTools(deeplink.url),
                      onDuplicate: () => _duplicateDeeplink(deeplink),
                      onDelete: () => _confirmAndDeleteDeeplink(deeplink),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHomeBody(
    AsyncValue<List<Deeplink>> deeplinks,
    AsyncValue<List<Project>> projects,
    AsyncValue<List<DeeplinkHistory>> recentHistory,
  ) {
    final isLoading =
        (deeplinks.isLoading && !deeplinks.hasValue) ||
        (projects.isLoading && !projects.hasValue) ||
        (recentHistory.isLoading && !recentHistory.hasValue);

    if (isLoading) {
      return const AppLoadingState();
    }

    final hasError =
        deeplinks.hasError || projects.hasError || recentHistory.hasError;

    if (hasError) {
      return Center(
        child: AppErrorState(
          title: 'Unable to load Home',
          description: 'Please try again later.',
          onRetry: () {
            ref.invalidate(allDeeplinksProvider);
            ref.invalidate(projectsProvider);
            ref.invalidate(recentHistoryProvider(3));
          },
        ),
      );
    }

    final allDeeplinks = deeplinks.value ?? const <Deeplink>[];
    final allProjects = projects.value ?? const <Project>[];
    final recentHistoryItems = recentHistory.value ?? const <DeeplinkHistory>[];
    final projectCounts = _buildProjectCounts(allDeeplinks);

    if (_isSearching) {
      return _HomeSearchResults(
        query: _searchQuery,
        deeplinks: allDeeplinks,
        projects: allProjects,
        projectCounts: projectCounts,
        onDeeplinkTap: _openEditScreen,
        onDeeplinkOpen: _openDeeplink,
        openingDeeplinkIds: _openingDeeplinkIds,
        onProjectTap: _openProjectFromDashboard,
      );
    }

    return _HomeDashboard(
      clipboardQuickLinkUrl: _clipboardQuickLinkUrl,
      isOpeningClipboardQuickLink: _isOpeningClipboardQuickLink,
      recentHistoryItems: recentHistoryItems,
      favoriteDeeplinks: _buildDashboardFavorites(allDeeplinks),
      recentProjects: allProjects.take(3).toList(),
      projectCounts: projectCounts,
      terminalDispatchUrl: _buildTerminalDispatchUrl(
        clipboardQuickLinkUrl: _clipboardQuickLinkUrl,
        recentHistoryItems: recentHistoryItems,
        favoriteDeeplinks: _buildDashboardFavorites(allDeeplinks),
      ),
      openingHistoryIds: _openingHistoryIds,
      openingDeeplinkIds: _openingDeeplinkIds,
      onOpenClipboardQuickLink: _openClipboardQuickLink,
      onSaveEditClipboardQuickLink: _saveEditClipboardQuickLink,
      onSeeAllHistory: () => context.goNamed(AppRoute.history.name),
      onSeeAllFavorites: () => context.goNamed(AppRoute.favorites.name),
      onSeeAllProjects: () => context.goNamed(AppRoute.projects.name),
      onOpenHistoryItem: _reopenHistoryItem,
      onOpenFavorite: _openDeeplink,
      onFavoriteTap: _openEditScreen,
      onProjectTap: _openProjectFromDashboard,
      onCopyTerminalCommand: _copyText,
    );
  }

  Widget _emptyStateForVisibleDeeplinks({
    required bool hasSearchQuery,
    required String query,
  }) {
    if (hasSearchQuery) {
      return AppEmptyState(
        icon: Icons.search_off,
        title: 'No results for "$query"',
        description: 'Try a different search term.',
      );
    }

    if (widget.favoritesOnly) {
      return const AppEmptyState(
        icon: Icons.star_border,
        title: 'No favorite deeplinks',
        description: 'Mark a deeplink as favorite to find it here.',
      );
    }

    return const AppEmptyState(
      icon: Icons.link_off,
      title: 'No deeplinks yet',
      description: 'Create a deeplink to get started.',
    );
  }

  void _syncCurrentProject(AsyncValue<List<Project>> projects) {
    final currentProjectId = ref.read(currentProjectIdProvider);

    projects.whenData((projects) {
      if (projects.isEmpty) {
        return;
      }

      final currentIsValid = projects.any(
        (project) => project.id == currentProjectId,
      );

      if (currentProjectId != null && currentIsValid) {
        return;
      }

      final defaultProject = projects.where(
        (project) => project.name == AppDatabase.defaultProjectName,
      );
      final nextProject = defaultProject.isNotEmpty
          ? defaultProject.first
          : projects.first;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ref.read(currentProjectIdProvider.notifier).select(nextProject.id);
        ref.read(currentEnvironmentIdProvider.notifier).select(null);
      });
    });
  }

  void _syncCurrentEnvironment(AsyncValue<List<Environment>> environments) {
    final currentEnvironmentId = ref.read(currentEnvironmentIdProvider);

    if (currentEnvironmentId == null) {
      return;
    }

    environments.whenData((environments) {
      final currentIsValid = environments.any(
        (environment) => environment.id == currentEnvironmentId,
      );

      if (currentIsValid) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ref.read(currentEnvironmentIdProvider.notifier).select(null);
      });
    });
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

  Future<void> _refreshClipboardQuickLink() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      final isValid =
          text != null && DeeplinkValidator.validateUrl(text) == null;

      if (!mounted) {
        return;
      }

      setState(() {
        _clipboardQuickLinkUrl = isValid ? text : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _clipboardQuickLinkUrl = null;
      });
    }
  }

  Map<int, int> _buildProjectCounts(List<Deeplink> deeplinks) {
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

  List<Deeplink> _buildDashboardFavorites(List<Deeplink> deeplinks) {
    final favorites = deeplinks
        .where((deeplink) => deeplink.isFavorite)
        .toList();

    favorites.sort((a, b) {
      final aLastOpenedAt = a.lastOpenedAt;
      final bLastOpenedAt = b.lastOpenedAt;

      if (aLastOpenedAt != null && bLastOpenedAt != null) {
        final comparison = bLastOpenedAt.compareTo(aLastOpenedAt);

        if (comparison != 0) {
          return comparison;
        }
      } else if (aLastOpenedAt != null) {
        return -1;
      } else if (bLastOpenedAt != null) {
        return 1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });

    return favorites.take(3).toList();
  }

  String? _buildTerminalDispatchUrl({
    required String? clipboardQuickLinkUrl,
    required List<DeeplinkHistory> recentHistoryItems,
    required List<Deeplink> favoriteDeeplinks,
  }) {
    if (clipboardQuickLinkUrl != null) {
      return clipboardQuickLinkUrl;
    }

    if (recentHistoryItems.isNotEmpty) {
      return recentHistoryItems.first.url;
    }

    if (favoriteDeeplinks.isNotEmpty) {
      return favoriteDeeplinks.first.url;
    }

    return null;
  }

  Future<void> _openClipboardQuickLink() async {
    final url = _clipboardQuickLinkUrl;

    if (url == null || _isOpeningClipboardQuickLink) {
      return;
    }

    setState(() {
      _isOpeningClipboardQuickLink = true;
    });

    try {
      await _openUrlAndRecordHistory(name: _clipboardHistoryName, url: url);
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningClipboardQuickLink = false;
        });
      }
    }
  }

  Future<void> _saveEditClipboardQuickLink() async {
    final url = _clipboardQuickLinkUrl;

    if (url == null) {
      return;
    }

    await context.pushNamed(AppRoute.addDeeplink.name, extra: url);

    if (mounted) {
      _refreshClipboardQuickLink();
    }
  }

  Future<void> _reopenHistoryItem(DeeplinkHistory history) async {
    if (_openingHistoryIds.contains(history.id)) {
      return;
    }

    setState(() {
      _openingHistoryIds.add(history.id);
    });

    try {
      await _openUrlAndRecordHistory(name: history.name, url: history.url);
    } finally {
      if (mounted) {
        setState(() {
          _openingHistoryIds.remove(history.id);
        });
      }
    }
  }

  Future<void> _openUrlAndRecordHistory({
    required String name,
    required String url,
  }) async {
    final trimmedUrl = url.trim();
    final validationError = DeeplinkValidator.validateUrl(trimmedUrl);
    final historyRepository = ref.read(historyRepositoryProvider);

    if (validationError != null) {
      await _recordStandaloneOpenHistory(
        historyRepository,
        name: name,
        url: trimmedUrl,
        isSuccess: false,
        errorMessage: _invalidHistoryMessage,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(validationError);
      return;
    }

    try {
      final launcher = ref.read(deeplinkLauncherProvider);
      final launched = await launcher.open(Uri.parse(trimmedUrl));

      if (launched) {
        await _recordStandaloneOpenHistory(
          historyRepository,
          name: name,
          url: trimmedUrl,
          isSuccess: true,
        );
        return;
      }

      await _recordStandaloneOpenHistory(
        historyRepository,
        name: name,
        url: trimmedUrl,
        isSuccess: false,
        errorMessage: _noHandlerMessage,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(_noHandlerMessage);
    } catch (_) {
      await _recordStandaloneOpenHistory(
        historyRepository,
        name: name,
        url: trimmedUrl,
        isSuccess: false,
        errorMessage: _unableToOpenMessage,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(_unableToOpenMessage);
    }
  }

  Future<void> _recordStandaloneOpenHistory(
    HistoryRepository repository, {
    required String name,
    required String url,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    try {
      await repository.createHistory(
        name: name,
        url: url,
        isSuccess: isSuccess,
        errorMessage: errorMessage,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Deeplink opened, but history could not be saved.');
    }
  }

  void _openProjectFromDashboard(Project project) {
    ref.read(currentProjectIdProvider.notifier).select(project.id);
    ref.read(currentEnvironmentIdProvider.notifier).select(null);
    context.goNamed(AppRoute.projects.name);
  }

  List<Deeplink> _buildVisibleDeeplinks(
    List<Deeplink> deeplinks,
    String query, {
    required bool favoritesOnly,
    required DeeplinkSortOption sortOption,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final visibleDeeplinks = deeplinks.where((deeplink) {
      final description = deeplink.description;
      final matchesSearch =
          normalizedQuery.isEmpty ||
          deeplink.name.toLowerCase().contains(normalizedQuery) ||
          deeplink.url.toLowerCase().contains(normalizedQuery) ||
          (description?.toLowerCase().contains(normalizedQuery) ?? false);
      final matchesFavorite = !favoritesOnly || deeplink.isFavorite;

      return matchesSearch && matchesFavorite;
    }).toList();

    visibleDeeplinks.sort((a, b) {
      switch (sortOption) {
        case DeeplinkSortOption.recentlyUpdated:
          return b.updatedAt.compareTo(a.updatedAt);
        case DeeplinkSortOption.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case DeeplinkSortOption.mostOpened:
          final openCountComparison = b.openCount.compareTo(a.openCount);

          if (openCountComparison != 0) {
            return openCountComparison;
          }

          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return visibleDeeplinks;
  }

  void _openEditScreen(Deeplink deeplink) {
    context.pushNamed(
      AppRoute.editDeeplink.name,
      pathParameters: {'id': deeplink.id.toString()},
    );
  }

  Future<void> _copyDeeplinkUrl(String url) async {
    return _copyText(url, 'Deeplink copied.', 'Unable to copy deeplink.');
  }

  Future<void> _copyText(
    String text,
    String successMessage, [
    String failureMessage = 'Unable to copy to clipboard.',
  ]) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validationError)));
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(_noHandlerMessage)));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(_unableToOpenMessage)));
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deeplink opened, but history could not be saved.'),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Deeplink opened, but its usage could not be updated.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deeplink opened, but usage could not be saved.'),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This deeplink no longer exists.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorite.')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This deeplink no longer exists.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to duplicate deeplink.')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This deeplink no longer exists.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete deeplink.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingDeeplinkId = null;
        });
      }
    }
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.clipboardQuickLinkUrl,
    required this.isOpeningClipboardQuickLink,
    required this.recentHistoryItems,
    required this.favoriteDeeplinks,
    required this.recentProjects,
    required this.projectCounts,
    required this.terminalDispatchUrl,
    required this.openingHistoryIds,
    required this.openingDeeplinkIds,
    required this.onOpenClipboardQuickLink,
    required this.onSaveEditClipboardQuickLink,
    required this.onSeeAllHistory,
    required this.onSeeAllFavorites,
    required this.onSeeAllProjects,
    required this.onOpenHistoryItem,
    required this.onOpenFavorite,
    required this.onFavoriteTap,
    required this.onProjectTap,
    required this.onCopyTerminalCommand,
  });

  final String? clipboardQuickLinkUrl;
  final bool isOpeningClipboardQuickLink;
  final List<DeeplinkHistory> recentHistoryItems;
  final List<Deeplink> favoriteDeeplinks;
  final List<Project> recentProjects;
  final Map<int, int> projectCounts;
  final String? terminalDispatchUrl;
  final Set<int> openingHistoryIds;
  final Set<int> openingDeeplinkIds;
  final VoidCallback onOpenClipboardQuickLink;
  final VoidCallback onSaveEditClipboardQuickLink;
  final VoidCallback onSeeAllHistory;
  final VoidCallback onSeeAllFavorites;
  final VoidCallback onSeeAllProjects;
  final ValueChanged<DeeplinkHistory> onOpenHistoryItem;
  final ValueChanged<Deeplink> onOpenFavorite;
  final ValueChanged<Deeplink> onFavoriteTap;
  final ValueChanged<Project> onProjectTap;
  final Future<void> Function(String text, String successMessage)
  onCopyTerminalCommand;

  @override
  Widget build(BuildContext context) {
    final terminalDispatchUrl = this.terminalDispatchUrl;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        if (clipboardQuickLinkUrl != null) ...[
          QuickLinkCard(
            url: clipboardQuickLinkUrl!,
            isOpening: isOpeningClipboardQuickLink,
            onOpen: onOpenClipboardQuickLink,
            onSaveEdit: onSaveEditClipboardQuickLink,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        DashboardSection(
          title: 'Recently Opened',
          action: _SectionTextAction(
            label: 'See all',
            onPressed: onSeeAllHistory,
          ),
          child: recentHistoryItems.isEmpty
              ? const _DashboardMessage('No recent activity yet')
              : _DashboardList(
                  children: [
                    for (final history in recentHistoryItems)
                      _HistoryDashboardItem(
                        history: history,
                        isOpening: openingHistoryIds.contains(history.id),
                        onOpen: () => onOpenHistoryItem(history),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Favorites',
          action: _SectionTextAction(
            label: 'See all',
            onPressed: onSeeAllFavorites,
          ),
          child: favoriteDeeplinks.isEmpty
              ? const _DashboardMessage('No favorites yet')
              : _DashboardList(
                  children: [
                    for (final deeplink in favoriteDeeplinks)
                      _FavoriteDashboardItem(
                        deeplink: deeplink,
                        isOpening: openingDeeplinkIds.contains(deeplink.id),
                        onTap: () => onFavoriteTap(deeplink),
                        onOpen: () => onOpenFavorite(deeplink),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Recent Projects',
          action: _SectionTextAction(
            label: 'See all',
            onPressed: onSeeAllProjects,
          ),
          child: recentProjects.isEmpty
              ? const _DashboardMessage('No projects yet')
              : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.95,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final project in recentProjects)
                      _ProjectDashboardItem(
                        project: project,
                        deeplinkCount: projectCounts[project.id] ?? 0,
                        onTap: () => onProjectTap(project),
                      ),
                  ],
                ),
        ),
        if (terminalDispatchUrl != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _TerminalDispatchCard(
            url: terminalDispatchUrl,
            onCopyCommand: onCopyTerminalCommand,
          ),
        ],
      ],
    );
  }
}

class _HomeSearchResults extends StatelessWidget {
  const _HomeSearchResults({
    required this.query,
    required this.deeplinks,
    required this.projects,
    required this.projectCounts,
    required this.onDeeplinkTap,
    required this.onDeeplinkOpen,
    required this.openingDeeplinkIds,
    required this.onProjectTap,
  });

  final String query;
  final List<Deeplink> deeplinks;
  final List<Project> projects;
  final Map<int, int> projectCounts;
  final ValueChanged<Deeplink> onDeeplinkTap;
  final ValueChanged<Deeplink> onDeeplinkOpen;
  final Set<int> openingDeeplinkIds;
  final ValueChanged<Project> onProjectTap;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.search,
          title: 'Search saved content',
          description: 'Find deeplinks by name or URL, and projects by name.',
        ),
      );
    }

    final matchingDeeplinks = deeplinks.where((deeplink) {
      return deeplink.name.toLowerCase().contains(normalizedQuery) ||
          deeplink.url.toLowerCase().contains(normalizedQuery);
    }).toList();
    final matchingProjects = projects.where((project) {
      final description = project.description;

      return project.name.toLowerCase().contains(normalizedQuery) ||
          (description?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();

    if (matchingDeeplinks.isEmpty && matchingProjects.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.search_off,
          title: 'No results for "$query"',
          description: 'Try a different search term.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        DashboardSection(
          title: 'Deeplinks',
          child: matchingDeeplinks.isEmpty
              ? _DashboardMessage('No deeplink results for "$query"')
              : _DashboardList(
                  children: [
                    for (final deeplink in matchingDeeplinks)
                      _FavoriteDashboardItem(
                        deeplink: deeplink,
                        isOpening: openingDeeplinkIds.contains(deeplink.id),
                        onTap: () => onDeeplinkTap(deeplink),
                        onOpen: () => onDeeplinkOpen(deeplink),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Projects',
          child: matchingProjects.isEmpty
              ? _DashboardMessage('No project results for "$query"')
              : _DashboardList(
                  children: [
                    for (final project in matchingProjects)
                      _ProjectDashboardItem(
                        project: project,
                        deeplinkCount: projectCounts[project.id] ?? 0,
                        onTap: () => onProjectTap(project),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SectionTextAction extends StatelessWidget {
  const _SectionTextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF4F46E5),
        textStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _DashboardList extends StatelessWidget {
  const _DashboardList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _HistoryDashboardItem extends StatelessWidget {
  const _HistoryDashboardItem({
    required this.history,
    required this.isOpening,
    required this.onOpen,
  });

  final DeeplinkHistory history;
  final bool isOpening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: _homeCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _StatusDot(
              color: history.isSuccess
                  ? const Color(0xFF10B981)
                  : colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          history.name.isEmpty ? history.url : history.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _SchemeChip(url: history.url),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    history.url,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    DateTimeFormatter.compactDateTime(history.openedAt),
                    style: textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: const Color(0xFF67E8F9),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: isOpening ? null : onOpen,
              icon: isOpening
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new, size: 18),
              label: const Text('Launch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteDashboardItem extends StatelessWidget {
  const _FavoriteDashboardItem({
    required this.deeplink,
    required this.isOpening,
    required this.onTap,
    required this.onOpen,
  });

  final Deeplink deeplink;
  final bool isOpening;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: _homeCardDecoration().copyWith(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF0FDFA)],
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(Icons.star, color: Color(0xFFF59E0B)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deeplink.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        deeplink.url,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: const Color(0xFF020617),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: isOpening ? null : onOpen,
                  icon: isOpening
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rocket_launch, size: 18),
                  label: const Text('Open'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectDashboardItem extends StatelessWidget {
  const _ProjectDashboardItem({
    required this.project,
    required this.deeplinkCount,
    required this.onTap,
  });

  final Project project;
  final int deeplinkCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: _homeCardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: SizedBox(
            height: 144,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: Icon(
                            Icons.folder_outlined,
                            color: Color(0xFF0891B2),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _CountPill(label: _deeplinkCountLabel),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    project.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    DateTimeFormatter.compactDateTime(project.updatedAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _deeplinkCountLabel {
    if (deeplinkCount == 1) {
      return '1 link';
    }

    return '$deeplinkCount links';
  }
}

class _TerminalDispatchCard extends StatelessWidget {
  const _TerminalDispatchCard({required this.url, required this.onCopyCommand});

  final String url;
  final Future<void> Function(String text, String successMessage) onCopyCommand;

  @override
  Widget build(BuildContext context) {
    final command = buildAdbCommand(url);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: Color(0xFF22D3EE), size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Terminal Dispatch',
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'ADB / XCRUN',
                  style: textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF22D3EE),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      r'$',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF22D3EE),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        command,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFCBD5E1),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy ADB command',
                      onPressed: () =>
                          onCopyCommand(command, 'ADB command copied.'),
                      icon: const Icon(
                        Icons.content_copy,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8),
        ],
      ),
      child: const SizedBox.square(dimension: 12),
    );
  }
}

class _SchemeChip extends StatelessWidget {
  const _SchemeChip({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Uri.tryParse(url)?.scheme;

    if (scheme == null || scheme.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFA5F3FC)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          scheme.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF0E7490),
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF475569),
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _homeCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: const [
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 2)),
    ],
  );
}

class _HomeBrandIcon extends StatelessWidget {
  const _HomeBrandIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22D3EE), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322D3EE),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const SizedBox.square(
        dimension: 44,
        child: Icon(Icons.link, color: Colors.white),
      ),
    );
  }
}

enum DeeplinkSortOption {
  recentlyUpdated('Recently'),
  name('Name'),
  mostOpened('Most opened');

  const DeeplinkSortOption(this.label);

  final String label;
}
