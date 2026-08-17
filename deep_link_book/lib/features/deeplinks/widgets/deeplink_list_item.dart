import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';

class DeeplinkListItem extends StatelessWidget {
  const DeeplinkListItem({
    super.key,
    required this.deeplink,
    this.isProcessing = false,
    this.isFavoriteProcessing = false,
    this.isOpening = false,
    this.onTap,
    this.onOpen,
    this.onFavoriteTap,
    this.onEdit,
    this.onCopy,
    this.onDuplicate,
    this.onDelete,
  });

  final Deeplink deeplink;
  final bool isProcessing;
  final bool isFavoriteProcessing;
  final bool isOpening;
  final VoidCallback? onTap;
  final VoidCallback? onOpen;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      title: Text(
        deeplink.name,
        style: textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(
            deeplink.url,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _openCountLabel,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: 'Open ${deeplink.name}',
              child: OutlinedButton.icon(
                onPressed: isOpening ? null : onOpen,
                icon: isOpening
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFavoriteProcessing)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              tooltip: deeplink.isFavorite
                  ? 'Remove ${deeplink.name} from favorites'
                  : 'Add ${deeplink.name} to favorites',
              onPressed: onFavoriteTap,
              icon: Icon(
                deeplink.isFavorite ? Icons.star : Icons.star_border,
                color: deeplink.isFavorite
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          if (isProcessing)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            PopupMenuButton<_DeeplinkListItemAction>(
              tooltip: 'Actions for ${deeplink.name}',
              onSelected: (action) {
                switch (action) {
                  case _DeeplinkListItemAction.edit:
                    onEdit?.call();
                  case _DeeplinkListItemAction.copy:
                    onCopy?.call();
                  case _DeeplinkListItemAction.duplicate:
                    onDuplicate?.call();
                  case _DeeplinkListItemAction.delete:
                    onDelete?.call();
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: _DeeplinkListItemAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _DeeplinkListItemAction.copy,
                    child: Text('Copy'),
                  ),
                  PopupMenuItem(
                    value: _DeeplinkListItemAction.duplicate,
                    child: Text('Duplicate'),
                  ),
                  PopupMenuItem(
                    value: _DeeplinkListItemAction.delete,
                    child: Text('Delete'),
                  ),
                ];
              },
            ),
        ],
      ),
    );
  }

  String get _openCountLabel {
    if (deeplink.openCount == 1) {
      return 'Opened 1 time';
    }

    return 'Opened ${deeplink.openCount} times';
  }
}

enum _DeeplinkListItemAction { edit, copy, duplicate, delete }
