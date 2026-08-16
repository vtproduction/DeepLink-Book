import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/deeplink/deeplink_launcher.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
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
  bool _isClearingHistory = false;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final historyItems = history.asData?.value ?? const <DeeplinkHistory>[];
    final canClearHistory =
        history.hasValue && historyItems.isNotEmpty && !_isClearingHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (history.hasValue && historyItems.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              onPressed: canClearHistory ? _confirmAndClearHistory : null,
              icon: _isClearingHistory
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load history.',
            description: 'Please try again later.',
          ),
        ),
        data: (historyItems) {
          if (historyItems.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.history,
                title: 'No history yet',
                description: 'Opened deeplinks will appear here.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              final historyItem = historyItems[index];

              return HistoryListItem(
                history: historyItem,
                isOpening: _openingHistoryIds.contains(historyItem.id),
                isDeleting: _deletingHistoryIds.contains(historyItem.id),
                onOpen: () => _reopenHistoryItem(historyItem),
                onDelete: () => _confirmAndDeleteHistoryItem(historyItem),
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          );
        },
      ),
    );
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

  Future<void> _confirmAndClearHistory() async {
    if (_isClearingHistory) {
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Clear all history?',
      message: 'All history entries will be permanently removed.',
      confirmLabel: 'Clear',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _isClearingHistory = true;
    });

    try {
      await ref.read(historyRepositoryProvider).clearHistory();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to clear history.');
    } finally {
      if (mounted) {
        setState(() {
          _isClearingHistory = false;
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
