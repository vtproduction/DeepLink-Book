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
    if (cardLayout) {
      return _buildCard(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      leading: isFavoriteProcessing
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              deeplink.isFavorite ? Icons.star : Icons.star_border,
              color: deeplink.isFavorite
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
      title: Text(
        deeplink.name,
        style: textTheme.titleSmall,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  _usageMetadataLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Open ${deeplink.name}',
                onPressed: isOpening ? null : onOpen,
                icon: isOpening
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new),
              ),
              IconButton(
                tooltip: 'Copy ${deeplink.name}',
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProcessing)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            _buildOverflowMenu(context),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D091E42),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _FavoriteIndicator(isLoading: isFavoriteProcessing),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      deeplink.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0B1329),
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SchemeBadge(label: _schemeLabel),
                  if (isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    _buildOverflowMenu(context),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      deeplink.url,
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF475569),
                        fontFamily: 'monospace',
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _usageMetadataLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF0F766E),
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: Color(0xFFEFF3F6)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Copy ${deeplink.name}',
                    onPressed: onCopy,
                    color: const Color(0xFF64748B),
                    icon: const Icon(Icons.content_copy, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton.icon(
                    onPressed: isOpening ? null : onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1329),
                      foregroundColor: const Color(0xFF00E5FF),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      disabledForegroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: isOpening
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF64748B),
                            ),
                          )
                        : const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Launch'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverflowMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_DeeplinkListItemAction>(
      tooltip: 'More actions for ${deeplink.name}',
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
  const _FavoriteIndicator({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
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
              : const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isHttps ? const Color(0xFFEEF2FF) : const Color(0xFFECFEFF),
        border: Border.all(
          color: isHttps ? const Color(0xFFC7D2FE) : const Color(0xFFA5F3FC),
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isHttps ? const Color(0xFF4F46E5) : const Color(0xFF0F766E),
            fontWeight: FontWeight.w800,
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
