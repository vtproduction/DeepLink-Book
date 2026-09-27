import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_brand_icon.dart';
import '../../../app/widgets/app_root_top_bar.dart';
import '../../../core/database/app_database.dart';
import '../../../core/deeplink/deeplink_launcher.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../deeplinks/validation/deeplink_validator.dart';
import '../data/history_repository.dart';
import '../providers/history_providers.dart';
import '../widgets/history_list_item.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _invalidHistoryMessage = 'Invalid deeplink URL.';
  static const _noHandlerMessage = 'No app can open this deeplink.';
  static const _unableToOpenMessage = 'Unable to open deeplink.';
  static const _historySaveFailureMessage =
      'Deeplink opened, but history could not be saved.';

  final _openingHistoryIds = <int>{};
  final _deletingHistoryIds = <int>{};
  var _searchQuery = '';
  var _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppRootTopBar(
          title: 'Deep Link Studio',
          eyebrow: 'History',
          leading: const AppBrandIcon(),
          searchQuery: _searchQuery,
          isSearching: _isSearching,
          onSearchPressed: _startSearch,
          onSearchQueryChanged: _updateSearchQuery,
          onSearchClose: _closeSearch,
          onSettingsPressed: _openSettings,
        ),
        body: history.when(
          loading: () => const AppLoadingState(),
          error: (error, stackTrace) => Center(
            child: AppErrorState(
              title: 'Unable to load history',
              description: 'Please try again later.',
              onRetry: () => ref.invalidate(historyProvider),
            ),
          ),
          data: (historyItems) {
            final visibleHistoryItems = _buildVisibleHistoryItems(
              historyItems,
              _searchQuery,
            );
            final hasSearchQuery = _searchQuery.trim().isNotEmpty;

            if (visibleHistoryItems.isEmpty) {
              return Center(
                child: AppEmptyState(
                  icon: hasSearchQuery ? Icons.search_off : Icons.history,
                  title: hasSearchQuery
                      ? 'No results for "$_searchQuery"'
                      : 'No history yet',
                  description: hasSearchQuery
                      ? 'Try a different search term.'
                      : 'Deeplinks you open will appear here.',
                ),
              );
            }

            final groups = _buildHistoryGroups(visibleHistoryItems);
            final successCount = visibleHistoryItems
                .where((history) => history.isSuccess)
                .length;
            final failedCount = visibleHistoryItems.length - successCount;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                _HistoryPageHeader(
                  totalCount: visibleHistoryItems.length,
                  successCount: successCount,
                  failedCount: failedCount,
                  latestOpenedAt: visibleHistoryItems.first.openedAt,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final group in groups) ...[
                  _HistoryGroupHeader(
                    label: group.label,
                    count: group.items.length,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (var index = 0; index < group.items.length; index++) ...[
                    HistoryListItem(
                      history: group.items[index],
                      isOpening: _openingHistoryIds.contains(
                        group.items[index].id,
                      ),
                      isDeleting: _deletingHistoryIds.contains(
                        group.items[index].id,
                      ),
                      onOpen: () => _reopenHistoryItem(group.items[index]),
                      onCopy: () => _copyDeeplinkUrl(group.items[index].url),
                      onDelete: () =>
                          _confirmAndDeleteHistoryItem(group.items[index]),
                    ),
                    if (index != group.items.length - 1) const Divider(),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<DeeplinkHistory> _buildVisibleHistoryItems(
    List<DeeplinkHistory> historyItems,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return historyItems;
    }

    return historyItems.where((history) {
      return history.name.toLowerCase().contains(normalizedQuery) ||
          history.url.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  List<_HistoryDateGroup> _buildHistoryGroups(
    List<DeeplinkHistory> historyItems,
  ) {
    final groups = <_HistoryDateGroup>[];

    for (final history in historyItems) {
      final label = _historyDateLabel(history.openedAt);

      if (groups.isNotEmpty && groups.last.label == label) {
        groups.last.items.add(history);
      } else {
        groups.add(_HistoryDateGroup(label: label, items: [history]));
      }
    }

    return groups;
  }

  String _historyDateLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(local.year, local.month, local.day);
    final difference = today.difference(itemDate).inDays;

    if (difference == 0) {
      return 'Today — ${_monthNames[local.month - 1]} ${local.day}, ${local.year}';
    }

    if (difference == 1) {
      return 'Yesterday — ${_monthNames[local.month - 1]} ${local.day}, ${local.year}';
    }

    return '${_monthNames[local.month - 1]} ${local.day}, ${local.year}';
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

  Future<void> _reopenHistoryItem(DeeplinkHistory history) async {
    if (_openingHistoryIds.contains(history.id)) {
      return;
    }

    setState(() {
      _openingHistoryIds.add(history.id);
    });

    try {
      final trimmedUrl = history.url.trim();
      final validationError = DeeplinkValidator.validateUrl(trimmedUrl);
      final repository = ref.read(historyRepositoryProvider);

      if (validationError != null) {
        await _recordReopenHistory(
          repository,
          history,
          isSuccess: false,
          errorMessage: _invalidHistoryMessage,
        );

        if (!mounted) {
          return;
        }

        _showSnackBar(validationError);
        return;
      }

      final launcher = ref.read(deeplinkLauncherProvider);
      final launched = await launcher.open(Uri.parse(trimmedUrl));

      if (launched) {
        final saved = await _recordReopenHistory(
          repository,
          history,
          isSuccess: true,
        );

        if (!mounted) {
          return;
        }

        if (!saved) {
          _showSnackBar(_historySaveFailureMessage);
        }
        return;
      }

      await _recordReopenHistory(
        repository,
        history,
        isSuccess: false,
        errorMessage: _noHandlerMessage,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(_noHandlerMessage);
    } catch (_) {
      try {
        await _recordReopenHistory(
          ref.read(historyRepositoryProvider),
          history,
          isSuccess: false,
          errorMessage: _unableToOpenMessage,
        );
      } catch (_) {
        // The user-facing error below is about the failed reopen attempt.
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(_unableToOpenMessage);
    } finally {
      if (mounted) {
        setState(() {
          _openingHistoryIds.remove(history.id);
        });
      }
    }
  }

  Future<bool> _recordReopenHistory(
    HistoryRepository repository,
    DeeplinkHistory history, {
    required bool isSuccess,
    String? errorMessage,
  }) async {
    try {
      await repository.createHistory(
        deeplinkId: history.deeplinkId,
        name: history.name,
        url: history.url,
        isSuccess: isSuccess,
        errorMessage: errorMessage,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _confirmAndDeleteHistoryItem(DeeplinkHistory history) async {
    if (_deletingHistoryIds.contains(history.id)) {
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete history item?',
      message: 'This history entry will be permanently removed.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _deletingHistoryIds.add(history.id);
    });

    try {
      final deleted = await ref
          .read(historyRepositoryProvider)
          .deleteHistory(history.id);

      if (!mounted) {
        return;
      }

      if (!deleted) {
        _showSnackBar('This history item no longer exists.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to delete history item.');
    } finally {
      if (mounted) {
        setState(() {
          _deletingHistoryIds.remove(history.id);
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _HistoryDateGroup {
  _HistoryDateGroup({required this.label, required this.items});

  final String label;
  final List<DeeplinkHistory> items;
}

class _HistoryPageHeader extends StatelessWidget {
  const _HistoryPageHeader({
    required this.totalCount,
    required this.successCount,
    required this.failedCount,
    required this.latestOpenedAt,
  });

  final int totalCount;
  final int successCount;
  final int failedCount;
  final DateTime latestOpenedAt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 8),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'INSPECTOR LOG',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.55,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.history, size: 15, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCount ${totalCount == 1 ? 'launch' : 'launches'} recorded',
                        style: textTheme.labelSmall,
                      ),
                      Text(
                        'Last dispatched ${DateTimeFormatter.compactDateTime(latestOpenedAt)}',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                _HistoryCountBadge(
                  label: '$successCount pass',
                  foregroundColor: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                ),
                const SizedBox(width: AppSpacing.xs),
                _HistoryCountBadge(
                  label: '$failedCount fail',
                  foregroundColor: colorScheme.onErrorContainer,
                  backgroundColor: colorScheme.errorContainer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryCountBadge extends StatelessWidget {
  const _HistoryCountBadge({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.compact,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foregroundColor,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _HistoryGroupHeader extends StatelessWidget {
  const _HistoryGroupHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.55,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              '$count',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
