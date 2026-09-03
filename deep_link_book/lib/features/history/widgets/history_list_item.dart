import 'package:flutter/material.dart';

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
    final statusColor = history.isSuccess
        ? colorScheme.primary
        : colorScheme.error;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            history.isSuccess ? Icons.check_circle : Icons.error,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              history.name.isEmpty ? history.url : history.name,
              style: textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              history.url,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!history.isSuccess &&
                history.errorMessage != null &&
                history.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                history.errorMessage!,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _timeLabel(history.openedAt),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Open ${history.name}',
                  onPressed: isOpening ? null : onOpen,
                  icon: isOpening
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.open_in_new),
                ),
                IconButton(
                  tooltip: 'Copy ${history.name}',
                  onPressed: onCopy,
                  icon: const Icon(Icons.content_copy),
                ),
                if (isDeleting)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  PopupMenuButton<_HistoryItemAction>(
                    tooltip: 'More history actions',
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
    );
  }

  String _timeLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

enum _HistoryItemAction { delete }
