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
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick Link',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              url,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
              softWrap: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Open clipboard deeplink',
                  onPressed: isOpening ? null : onOpen,
                  icon: isOpening
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.open_in_new),
                ),
                IconButton(
                  tooltip: 'Edit and save clipboard deeplink',
                  onPressed: onSaveEdit,
                  icon: const Icon(Icons.add_link),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
