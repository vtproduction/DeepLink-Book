import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

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
import '../../history/data/history_repository.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: deeplinks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load deeplinks',
            description: 'Please try again later.',
          ),
        ),
        data: (deeplinks) {
          if (deeplinks.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.link_off,
                title: 'No deeplinks yet',
                description: 'Create your first deeplink to get started.',
              ),
            );
          }

          final filteredDeeplinks = _filterDeeplinks(
            deeplinks,
            _searchController.text,
          );

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
              if (filteredDeeplinks.isEmpty)
                const Expanded(
                  child: Center(
                    child: AppEmptyState(
                      icon: Icons.search_off,
                      title: 'No matching deeplinks',
                      description: 'Try a different search term.',
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
                    itemCount: filteredDeeplinks.length,
                    itemBuilder: (context, index) {
                      final deeplink = filteredDeeplinks[index];

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
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Deeplink',
        onPressed: () => context.pushNamed(AppRoute.addDeeplink.name),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Deeplink> _filterDeeplinks(List<Deeplink> deeplinks, String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return deeplinks;
    }

    return deeplinks.where((deeplink) {
      final description = deeplink.description;

      return deeplink.name.toLowerCase().contains(normalizedQuery) ||
          deeplink.url.toLowerCase().contains(normalizedQuery) ||
          (description?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();
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
