import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';

class QuickLinkCard extends StatelessWidget {
  const QuickLinkCard({
    super.key,
    required this.url,
    required this.onOpen,
    required this.onSaveEdit,
    this.isOpening = false,
  });

  final String url;
  final VoidCallback onOpen;
  final VoidCallback onSaveEdit;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const SizedBox.square(
                    dimension: 28,
                    child: Icon(
                      Icons.content_paste_go_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clipboard Deeplink Detected',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        url,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 18 / 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Valid deeplink detected from clipboard',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ColoredBox(
            color: colorScheme.surface.withValues(alpha: 0.6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.card,
                AppSpacing.sm,
                AppSpacing.card,
                AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onSaveEdit,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 15),
                    label: const Text('Save Link'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton.icon(
                    onPressed: isOpening ? null : onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.card,
                      ),
                    ),
                    icon: isOpening
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Dispatch Now'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
