import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_formatter.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  history.name,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _HistoryStatus(isSuccess: history.isSuccess, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              history.errorMessage!,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            DateTimeFormatter.dateTimeWithYear(history.openedAt),
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              FilledButton.icon(
                onPressed: isOpening ? null : onOpen,
                icon: isOpening
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new),
                label: Text(isOpening ? 'Opening' : 'Open'),
              ),
              const Spacer(),
              PopupMenuButton<_HistoryItemAction>(
                enabled: !isDeleting,
                tooltip: 'History actions',
                onSelected: (action) {
                  switch (action) {
                    case _HistoryItemAction.copy:
                      onCopy?.call();
                    case _HistoryItemAction.delete:
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _HistoryItemAction.copy,
                    child: Text('Copy'),
                  ),
                  PopupMenuItem(
                    value: _HistoryItemAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _HistoryItemAction { copy, delete }

class _HistoryStatus extends StatelessWidget {
  const _HistoryStatus({required this.isSuccess, required this.color});

  final bool isSuccess;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: color,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          isSuccess ? 'Success' : 'Failed',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}
