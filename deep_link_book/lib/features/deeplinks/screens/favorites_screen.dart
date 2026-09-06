import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_root_top_bar.dart';
import '../../../core/database/app_database.dart';
import '../../../core/deeplink/deeplink_launcher.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../history/data/history_repository.dart';
import '../data/deeplink_repository.dart';
import '../developer_tools/developer_tools_view.dart';
import '../providers/deeplink_providers.dart';
import '../validation/deeplink_validator.dart';
import '../widgets/deeplink_list_item.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  static const _invalidHistoryMessage = 'Invalid deeplink URL.';
  static const _noHandlerMessage = 'No app can open this deeplink.';
  static const _unableToOpenMessage = 'Unable to open deeplink.';

  int? _processingDeeplinkId;
  final _processingFavoriteIds = <int>{};
  final _openingDeeplinkIds = <int>{};
  var _searchQuery = '';
  var _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final deeplinks = ref.watch(allDeeplinksProvider);

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F8F9),
        appBar: AppRootTopBar(
          title: 'Deep Link Book',
          searchQuery: _searchQuery,
          isSearching: _isSearching,
          onSearchPressed: _startSearch,
          onSearchQueryChanged: _updateSearchQuery,
          onSearchClose: _closeSearch,
          onSettingsPressed: _openSettings,
          eyebrow: 'Dev Suite',
          leading: const _FavoritesBrandIcon(),
        ),
        body: deeplinks.when(
          loading: () => const AppLoadingState(),
          error: (error, stackTrace) => Center(
            child: AppErrorState(
              title: 'Unable to load favorites',
              description: 'Please try again later.',
              onRetry: () => ref.invalidate(allDeeplinksProvider),
            ),
          ),
          data: (deeplinks) {
            final visibleFavorites = _buildVisibleFavorites(
              deeplinks,
              _searchQuery,
            );
            final hasSearchQuery = _searchQuery.trim().isNotEmpty;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                _FavoritesPageHeader(count: visibleFavorites.length),
                const SizedBox(height: AppSpacing.lg),
                if (visibleFavorites.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: AppEmptyState(
                      icon: hasSearchQuery
                          ? Icons.search_off
                          : Icons.star_border,
                      title: hasSearchQuery
                          ? 'No results for "$_searchQuery"'
                          : 'No favorites yet',
                      description: hasSearchQuery
                          ? 'Try a different search term.'
                          : 'Favorite a deeplink to access it quickly.',
                    ),
                  )
                else
                  for (
                    var index = 0;
                    index < visibleFavorites.length;
                    index++
                  ) ...[
                    DeeplinkListItem(
                      deeplink: visibleFavorites[index],
                      cardLayout: true,
                      isProcessing:
                          _processingDeeplinkId == visibleFavorites[index].id,
                      isFavoriteProcessing: _processingFavoriteIds.contains(
                        visibleFavorites[index].id,
                      ),
                      isOpening: _openingDeeplinkIds.contains(
                        visibleFavorites[index].id,
                      ),
                      onTap: () => _openEditScreen(visibleFavorites[index]),
                      onOpen: () => _openDeeplink(visibleFavorites[index]),
                      onFavoriteTap: () =>
                          _toggleFavorite(visibleFavorites[index]),
                      onEdit: () => _openEditScreen(visibleFavorites[index]),
                      onCopy: () =>
                          _copyDeeplinkUrl(visibleFavorites[index].url),
                      onDeveloperTools: () =>
                          _showDeveloperTools(visibleFavorites[index].url),
                      onDuplicate: () =>
                          _duplicateDeeplink(visibleFavorites[index]),
                      onDelete: () =>
                          _confirmAndDeleteDeeplink(visibleFavorites[index]),
                    ),
                    if (index != visibleFavorites.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Deeplink> _buildVisibleFavorites(
    List<Deeplink> deeplinks,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    final favorites = deeplinks.where((deeplink) {
      if (!deeplink.isFavorite) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return deeplink.name.toLowerCase().contains(normalizedQuery) ||
          deeplink.url.toLowerCase().contains(normalizedQuery);
    }).toList();

    favorites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return favorites;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FavoritesPageHeader extends StatelessWidget {
  const _FavoritesPageHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Favorites',
              style: textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF0B1329),
                fontWeight: FontWeight.w900,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFCFFAFE),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '$count Starred',
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF115E59),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Quick access to your starred deeplinks',
          style: textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FavoritesBrandIcon extends StatelessWidget {
  const _FavoritesBrandIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF2563EB), Color(0xFF00E5FF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3300B4D8),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const SizedBox.square(
        dimension: 40,
        child: Icon(Icons.link, color: Colors.white, size: 22),
      ),
    );
  }
}
