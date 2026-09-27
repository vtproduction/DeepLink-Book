import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';

class HistoryListItem extends StatelessWidget {
  const HistoryListItem({
    super.key,
    required this.history,
    required this.onOpen,
    required this.onCopy,
    required this.onDelete,
    this.isOpening = false,
    this.isDeleting = false,
  });

  final DeeplinkHistory history;
  final VoidCallback? onOpen;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final bool isOpening;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = history.name.isEmpty ? history.url : history.name;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: _HistoryStatusIcon(isSuccess: history.isSuccess),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _SchemeBadge(label: _schemeLabel(history.url)),
                      const Spacer(),
                      Text(
                        _timeLabel(history.openedAt),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    history.url,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 18 / 13,
                      letterSpacing: -0.325,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: _HistoryStatusText(history: history)),
                      _HistoryIconAction(
                        tooltip: history.isSuccess
                            ? 'Open snapshot deeplink'
                            : 'Retry snapshot deeplink',
                        icon: history.isSuccess
                            ? Icons.open_in_new
                            : Icons.refresh,
                        isLoading: isOpening,
                        onPressed: isOpening ? null : onOpen,
                      ),
                      _HistoryIconAction(
                        tooltip: 'Copy snapshot URL',
                        icon: Icons.content_copy_outlined,
                        onPressed: onCopy,
                      ),
                      if (isDeleting)
                        const SizedBox.square(
                          dimension: 44,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        PopupMenuButton<_HistoryItemAction>(
                          tooltip: 'More history actions',
                          icon: const Icon(Icons.more_vert, size: 16),
                          onSelected: (action) {
                            switch (action) {
                              case _HistoryItemAction.delete:
                                onDelete?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: _HistoryItemAction.delete,
                              child: Text(
                                'Delete',
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _schemeLabel(String url) {
    final scheme = Uri.tryParse(url)?.scheme;

    if (scheme == null || scheme.isEmpty) {
      return 'url';
    }

    if (scheme == 'http' || scheme == 'https') {
      return 'universal';
    }

    return 'custom';
  }

  String _timeLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _HistoryStatusIcon extends StatelessWidget {
  const _HistoryStatusIcon({required this.isSuccess});

  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSuccess
            ? colorScheme.surfaceContainerHigh
            : colorScheme.errorContainer,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 20,
        child: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? colorScheme.primary : colorScheme.error,
          size: 13,
        ),
      ),
    );
  }
}

class _SchemeBadge extends StatelessWidget {
  const _SchemeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _HistoryStatusText extends StatelessWidget {
  const _HistoryStatusText({required this.history});

  final DeeplinkHistory history;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = history.errorMessage?.trim();

    return Text(
      history.isSuccess
          ? 'Opened successfully'
          : message == null || message.isEmpty
          ? 'Launch failed'
          : message,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: history.isSuccess ? colorScheme.primary : colorScheme.error,
        fontFamily: 'monospace',
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _HistoryIconAction extends StatelessWidget {
  const _HistoryIconAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      iconSize: 16,
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
    );
  }
}

enum _HistoryItemAction { delete }
