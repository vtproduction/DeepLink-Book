import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _AppBottomNavigation(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _AppBottomNavigation extends StatelessWidget {
  const _AppBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    (label: 'Studio', semanticLabel: 'Home', icon: Icons.terminal),
    (label: 'History', semanticLabel: 'History', icon: Icons.history),
    (
      label: 'Favorites',
      semanticLabel: 'Favorites',
      icon: Icons.star_border_rounded,
    ),
    (
      label: 'Projects',
      semanticLabel: 'Projects',
      icon: Icons.account_tree_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHome = selectedIndex == 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: (isHome ? colorScheme.surfaceContainerLow : colorScheme.surface)
            .withValues(alpha: isHome ? 0.9 : 0.95),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                for (var index = 0; index < _destinations.length; index++)
                  Expanded(
                    child: _AppNavigationDestination(
                      label: _destinations[index].label,
                      semanticLabel: _destinations[index].semanticLabel,
                      icon: _destinations[index].icon,
                      isSelected: index == selectedIndex,
                      selectedBackground: index == 0
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.surfaceContainer,
                      onTap: () => onDestinationSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppNavigationDestination extends StatelessWidget {
  const _AppNavigationDestination({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.isSelected,
    required this.selectedBackground,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final bool isSelected;
  final Color selectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final borderRadius = BorderRadius.circular(AppRadius.sm);

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Center(
              child: SizedBox(
                width: 56,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected ? selectedBackground : Colors.transparent,
                    borderRadius: borderRadius,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: foregroundColor),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        label,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
