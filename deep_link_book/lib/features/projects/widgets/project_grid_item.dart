import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_formatter.dart';

class ProjectGridItem extends StatelessWidget {
  const ProjectGridItem({
    super.key,
    required this.project,
    required this.deeplinkCount,
    required this.onTap,
  });

  final Project project;
  final int deeplinkCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final description = project.description?.trim();
    final accentColor = _accentColor;
    final accentContainerColor = _accentContainerColor;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: const Color(0x1A0F172A),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentContainerColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: SizedBox.square(
                      dimension: 38,
                      child: Icon(
                        Icons.folder_outlined,
                        color: accentColor,
                        size: 21,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentContainerColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        _deeplinkCountLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                project.name,
                style: textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description == null || description.isEmpty
                    ? 'No description'
                    : description,
                style: textTheme.labelSmall?.copyWith(
                  color: description == null || description.isEmpty
                      ? colorScheme.onSurfaceVariant
                      : accentColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const Divider(height: 1, color: Color(0xFFEFF3F6)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Updated ${DateTimeFormatter.compactDateTime(project.updatedAt)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _deeplinkCountLabel {
    if (deeplinkCount == 1) {
      return '1 link';
    }

    return '$deeplinkCount links';
  }

  Color get _accentColor => switch (project.id % 4) {
    0 => const Color(0xFF7C3AED),
    1 => const Color(0xFF0891B2),
    2 => const Color(0xFF4F46E5),
    _ => const Color(0xFFD97706),
  };

  Color get _accentContainerColor => switch (project.id % 4) {
    0 => const Color(0xFFF5F3FF),
    1 => const Color(0xFFECFEFF),
    2 => const Color(0xFFEEF2FF),
    _ => const Color(0xFFFFF7E6),
  };
}
