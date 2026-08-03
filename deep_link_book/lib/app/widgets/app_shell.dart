import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.goNamed(AppRoute.home.name);
            case 1:
              context.goNamed(AppRoute.history.name);
            case 2:
              context.goNamed(AppRoute.settings.name);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int get _selectedIndex {
    if (currentPath == AppRoute.history.path) {
      return 1;
    }

    if (currentPath == AppRoute.settings.path) {
      return 2;
    }

    return 0;
  }
}
