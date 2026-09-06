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
    final textTheme = Theme.of(context).textTheme;
    final title = history.name.isEmpty ? history.url : history.name;
    final borderColor = history.isSuccess
        ? const Color(0xFFE2E8F0)
        : const Color(0xFFFDA4AF);
    final dividerColor = history.isSuccess
        ? const Color(0xFFE2E8F0)
        : const Color(0xFFFECACA);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HistoryStatusIcon(isSuccess: history.isSuccess),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF020617),
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _SchemePill(label: _schemeLabel(history.url)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _OpenHistoryButton(
                  isSuccess: history.isSuccess,
                  isOpening: isOpening,
                  onPressed: onOpen,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        history.url,
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF475569),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy $title',
                      visualDensity: VisualDensity.compact,
                      onPressed: onCopy,
                      icon: const Icon(Icons.content_copy, size: 18),
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  _timeLabel(history.openedAt),
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF020617),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('•', style: TextStyle(color: Color(0xFF64748B))),
                ),
                Expanded(child: _HistoryStatusText(history: history)),
                if (isDeleting)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  PopupMenuButton<_HistoryItemAction>(
                    tooltip: 'More history actions',
                    icon: const Icon(Icons.more_horiz),
                    iconColor: const Color(0xFF94A3B8),
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
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

  String _schemeLabel(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toUpperCase();

    if (scheme == null || scheme.isEmpty) {
      return 'URL';
    }

    if (scheme == 'HTTP' || scheme == 'HTTPS') {
      return scheme;
    }

    return 'CUSTOM';
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
    final backgroundColor = isSuccess
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFFE4E6);
    final foregroundColor = isSuccess
        ? const Color(0xFF059669)
        : const Color(0xFFE11D48);

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: 24,
        child: Icon(
          isSuccess ? Icons.check : Icons.priority_high,
          color: foregroundColor,
          size: 16,
        ),
      ),
    );
  }
}

class _SchemePill extends StatelessWidget {
  const _SchemePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: const Color(0xFF67E8F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF006874),
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _OpenHistoryButton extends StatelessWidget {
  const _OpenHistoryButton({
    required this.isSuccess,
    required this.isOpening,
    required this.onPressed,
  });

  final bool isSuccess;
  final bool isOpening;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0B1329),
        foregroundColor: Colors.white,
        minimumSize: const Size(94, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      onPressed: isOpening ? null : onPressed,
      icon: isOpening
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.open_in_new, color: Color(0xFF22D3EE), size: 16),
      label: Text(isSuccess ? 'Reopen' : 'Retry'),
    );
  }
}

class _HistoryStatusText extends StatelessWidget {
  const _HistoryStatusText({required this.history});

  final DeeplinkHistory history;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (history.isSuccess) {
      return Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Text(
              'Opened',
              style: textTheme.labelSmall?.copyWith(
                color: const Color(0xFF047857),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    final message = history.errorMessage?.trim();

    return Text(
      message == null || message.isEmpty ? 'Launch failed' : message,
      style: textTheme.bodySmall?.copyWith(
        color: const Color(0xFFE11D48),
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

enum _HistoryItemAction { delete }
