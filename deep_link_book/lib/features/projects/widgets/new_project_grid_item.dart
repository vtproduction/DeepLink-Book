import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';

class NewProjectGridItem extends StatelessWidget {
  const NewProjectGridItem({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFFD9FBF4),
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: const Color(0x1A0F766E),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF5EEAD4), width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0F4EA),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    child: Text(
                      'QUICK ADD',
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF115E59),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A0F766E),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(Icons.add, color: colorScheme.primary, size: 30),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'New Project',
                style: textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Create folder or suite',
                style: textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
