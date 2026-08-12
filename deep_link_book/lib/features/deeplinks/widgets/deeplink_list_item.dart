import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';

class DeeplinkListItem extends StatelessWidget {
  const DeeplinkListItem({super.key, required this.deeplink});

  final Deeplink deeplink;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
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
        ],
      ),
      trailing: Icon(
        deeplink.isFavorite ? Icons.star : Icons.star_border,
        color: deeplink.isFavorite
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
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
