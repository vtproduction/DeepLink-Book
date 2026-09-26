import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_formatter.dart';

class DeeplinkListItem extends StatelessWidget {
  const DeeplinkListItem({
    super.key,
    required this.deeplink,
    this.cardLayout = false,
    this.isProcessing = false,
    this.isFavoriteProcessing = false,
    this.isOpening = false,
    this.onTap,
    this.onOpen,
    this.onFavoriteTap,
    this.onEdit,
    this.onCopy,
    this.onDeveloperTools,
    this.onDuplicate,
    this.onDelete,
  });

  final Deeplink deeplink;
  final bool cardLayout;
  final bool isProcessing;
  final bool isFavoriteProcessing;
  final bool isOpening;
  final VoidCallback? onTap;
  final VoidCallback? onOpen;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onDeveloperTools;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.md);

    return Material(
      color: cardLayout ? colorScheme.surface : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: cardLayout
            ? BorderSide(color: colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.card,
            vertical: cardLayout ? AppSpacing.card : AppSpacing.sm,
          ),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _FavoriteIndicator(
                    isFavorite: deeplink.isFavorite,
                    isLoading: isFavoriteProcessing,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      deeplink.name,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _SchemeBadge(label: _schemeLabel),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                deeplink.url,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 18 / 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _usageMetadataLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _buildActions(context),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = IconButton.styleFrom(
      minimumSize: const Size.square(44),
      foregroundColor: colorScheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Open ${deeplink.name}',
          onPressed: isOpening ? null : onOpen,
          style: style,
          icon: isOpening
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.open_in_new, size: 18),
        ),
        IconButton(
          tooltip: 'Copy ${deeplink.name}',
          onPressed: onCopy,
          style: style,
          icon: const Icon(Icons.content_copy, size: 18),
        ),
        if (isProcessing)
          const SizedBox.square(
            dimension: 44,
            child: Center(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          SizedBox.square(dimension: 44, child: _buildOverflowMenu(context)),
      ],
    );
  }

  Widget _buildOverflowMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_DeeplinkListItemAction>(
      tooltip: 'More actions for ${deeplink.name}',
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _DeeplinkListItemAction.edit:
            onEdit?.call();
          case _DeeplinkListItemAction.favorite:
            onFavoriteTap?.call();
          case _DeeplinkListItemAction.developerTools:
            onDeveloperTools?.call();
          case _DeeplinkListItemAction.duplicate:
            onDuplicate?.call();
          case _DeeplinkListItemAction.delete:
            onDelete?.call();
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: _DeeplinkListItemAction.edit,
            child: Text('Edit'),
          ),
          PopupMenuItem(
            value: _DeeplinkListItemAction.favorite,
            child: Text(deeplink.isFavorite ? 'Unfavorite' : 'Favorite'),
          ),
          const PopupMenuItem(
            value: _DeeplinkListItemAction.developerTools,
            child: Text('Tools'),
          ),
          const PopupMenuItem(
            value: _DeeplinkListItemAction.duplicate,
            child: Text('Duplicate'),
          ),
          PopupMenuItem(
            value: _DeeplinkListItemAction.delete,
            child: Text('Delete', style: TextStyle(color: colorScheme.error)),
          ),
        ];
      },
    );
  }

  String get _schemeLabel {
    final scheme = Uri.tryParse(deeplink.url)?.scheme.toUpperCase();

    if (scheme == null || scheme.isEmpty) {
      return 'URL';
    }

    if (scheme == 'HTTP' || scheme == 'HTTPS') {
      return scheme;
    }

    return 'CUSTOM';
  }

  String get _usageMetadataLabel {
    final openCount = _openCountLabel;
    final lastOpenedAt = deeplink.lastOpenedAt;

    if (lastOpenedAt == null) {
      return openCount;
    }

    return '$openCount · Last opened ${DateTimeFormatter.compactDateTime(lastOpenedAt)}';
  }

  String get _openCountLabel {
    if (deeplink.openCount == 0) {
      return 'Never opened';
    }

    if (deeplink.openCount == 1) {
      return 'Opened 1 time';
    }

    return 'Opened ${deeplink.openCount} times';
  }
}

class _FavoriteIndicator extends StatelessWidget {
  const _FavoriteIndicator({required this.isFavorite, required this.isLoading});

  final bool isFavorite;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isFavorite
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SizedBox.square(
        dimension: 28,
        child: Center(
          child: isLoading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 18,
                ),
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
    final isHttps = label == 'HTTPS';
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isHttps
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isHttps ? const Color(0xFF004B73) : colorScheme.primary,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

enum _DeeplinkListItemAction {
  edit,
  favorite,
  developerTools,
  duplicate,
  delete,
}
