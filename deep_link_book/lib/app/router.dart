import 'package:go_router/go_router.dart';

import 'widgets/app_shell.dart';
import '../features/deeplinks/screens/add_deeplink_screen.dart';
import '../features/deeplinks/screens/home_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/settings/screens/settings_screen.dart';

enum AppRoute {
  home(name: 'home', path: '/'),
  addDeeplink(name: 'add-deeplink', path: '/deeplinks/new'),
  history(name: 'history', path: '/history'),
  settings(name: 'settings', path: '/settings');

  const AppRoute({required this.name, required this.path});

  final String name;
  final String path;
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoute.home.path,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(currentPath: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoute.home.path,
            name: AppRoute.home.name,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoute.history.path,
            name: AppRoute.history.name,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoute.settings.path,
            name: AppRoute.settings.name,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.addDeeplink.path,
        name: AppRoute.addDeeplink.name,
        builder: (context, state) => const AddDeeplinkScreen(),
      ),
    ],
  );
}

final appRouter = createAppRouter();
