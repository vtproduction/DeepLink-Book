import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/deeplink/deeplink_launcher.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../data/deeplink_repository.dart';
import '../providers/deeplink_providers.dart';
import '../validation/deeplink_validator.dart';
import '../widgets/deeplink_list_item.dart';
import '../../environments/providers/environment_providers.dart';
import '../../history/data/history_repository.dart';
import '../../projects/providers/project_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _invalidHistoryMessage = 'Invalid deeplink URL.';
  static const _noHandlerMessage = 'No app can open this deeplink.';
  static const _unableToOpenMessage = 'Unable to open deeplink.';

  int? _processingDeeplinkId;
  final _processingFavoriteIds = <int>{};
  final _openingDeeplinkIds = <int>{};
  final _searchController = TextEditingController();
  var _favoritesOnly = false;
  var _sortOption = DeeplinkSortOption.recentlyUpdated;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deeplinks = ref.watch(deeplinksProvider);
    final projects = ref.watch(projectsProvider);
    final environments = ref.watch(environmentsForCurrentProjectProvider);

    _syncCurrentProject(projects);
    _syncCurrentEnvironment(environments);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          _ProjectEnvironmentControls(projects: projects),
          Expanded(
            child: deeplinks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load deeplinks',
                  description: 'Please try again.',
                  action: FilledButton.icon(
                    onPressed: () => ref.invalidate(deeplinksProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
              ),
              data: (deeplinks) {
                final visibleDeeplinks = _buildVisibleDeeplinks(
                  deeplinks,
                  _searchController.text,
                  favoritesOnly: _favoritesOnly,
                  sortOption: _sortOption,
                );
                final hasSearchQuery = _searchController.text.trim().isNotEmpty;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search deeplinks',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: !_favoritesOnly,
                            onSelected: (selected) {
                              if (!selected) {
                                return;
                              }

                              setState(() {
                                _favoritesOnly = false;
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('Favorites'),
                            avatar: const Icon(Icons.star),
                            selected: _favoritesOnly,
                            onSelected: (selected) {
                              setState(() {
                                _favoritesOnly = selected;
                              });
                            },
                          ),
                          PopupMenuButton<DeeplinkSortOption>(
                            tooltip: 'Sort deeplinks',
                            initialValue: _sortOption,
                            onSelected: (sortOption) {
                              setState(() {
                                _sortOption = sortOption;
                              });
                            },
                            itemBuilder: (context) {
                              return DeeplinkSortOption.values.map((
                                sortOption,
                              ) {
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
                            hasSourceDeeplinks: deeplinks.isNotEmpty,
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
                              isProcessing:
                                  _processingDeeplinkId == deeplink.id,
                              isFavoriteProcessing: _processingFavoriteIds
                                  .contains(deeplink.id),
                              isOpening: _openingDeeplinkIds.contains(
                                deeplink.id,
                              ),
                              onTap: () => _openEditScreen(deeplink),
                              onOpen: () => _openDeeplink(deeplink),
                              onFavoriteTap: () => _toggleFavorite(deeplink),
                              onEdit: () => _openEditScreen(deeplink),
                              onCopy: () => _copyDeeplinkUrl(deeplink.url),
                              onDuplicate: () => _duplicateDeeplink(deeplink),
                              onDelete: () =>
                                  _confirmAndDeleteDeeplink(deeplink),
                            );
                          },
                          separatorBuilder: (context, index) => const Divider(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add deeplink',
        onPressed: () => context.pushNamed(AppRoute.addDeeplink.name),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _emptyStateForVisibleDeeplinks({
    required bool hasSearchQuery,
    required bool hasSourceDeeplinks,
  }) {
    if (hasSearchQuery) {
      return const AppEmptyState(
        icon: Icons.search_off,
        title: 'No matching deeplinks',
        description: 'Try a different search term.',
      );
    }

    if (_favoritesOnly && hasSourceDeeplinks) {
      return const AppEmptyState(
        icon: Icons.star_border,
        title: 'No favorite deeplinks',
        description: 'Mark a deeplink as favorite to find it here.',
      );
    }

    return const AppEmptyState(
      icon: Icons.link_off,
      title: 'No deeplinks yet',
      description: 'Create a deeplink for this project or environment.',
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

  void _onSearchChanged() {
    setState(() {});
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
    try {
      await Clipboard.setData(ClipboardData(text: url));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deeplink copied.')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to copy deeplink.')));
    }
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

enum DeeplinkSortOption {
  recentlyUpdated('Recently'),
  name('Name'),
  mostOpened('Most opened');

  const DeeplinkSortOption(this.label);

  final String label;
}

class _ProjectEnvironmentControls extends ConsumerWidget {
  const _ProjectEnvironmentControls({required this.projects});

  final AsyncValue<List<Project>> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final environments = ref.watch(environmentsForCurrentProjectProvider);
    final currentProjectId = ref.watch(currentProjectIdProvider);
    final currentEnvironmentId = ref.watch(currentEnvironmentIdProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Project', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: projects.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) =>
                      const Text('Unable to load projects'),
                  data: (projects) {
                    if (projects.isEmpty) {
                      return const Text('No projects available');
                    }

                    return DropdownButtonFormField<int>(
                      key: ValueKey('project-$currentProjectId'),
                      initialValue: currentProjectId,
                      isExpanded: true,
                      items: projects.map((project) {
                        return DropdownMenuItem(
                          value: project.id,
                          child: Text(
                            project.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (projectId) {
                        ref
                            .read(currentProjectIdProvider.notifier)
                            .select(projectId);
                        ref
                            .read(currentEnvironmentIdProvider.notifier)
                            .select(null);
                      },
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Manage projects',
                onPressed: () => context.pushNamed(AppRoute.projects.name),
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Environment', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: environments.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) =>
                      const Text('Unable to load environments'),
                  data: (environments) {
                    final values = <DropdownMenuItem<int?>>[
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
                    ];

                    return DropdownButtonFormField<int?>(
                      key: ValueKey('environment-$currentEnvironmentId'),
                      initialValue: currentEnvironmentId,
                      isExpanded: true,
                      items: values,
                      onChanged: (environmentId) {
                        ref
                            .read(currentEnvironmentIdProvider.notifier)
                            .select(environmentId);
                      },
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Manage environments',
                onPressed: currentProjectId == null
                    ? null
                    : () => context.pushNamed(
                        AppRoute.environments.name,
                        pathParameters: {
                          'projectId': currentProjectId.toString(),
                        },
                      ),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
