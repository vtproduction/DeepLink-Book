import 'package:go_router/go_router.dart';

import 'widgets/app_shell.dart';
import '../features/deeplinks/screens/add_deeplink_screen.dart';
import '../features/deeplinks/screens/edit_deeplink_screen.dart';
import '../features/deeplinks/screens/favorites_screen.dart';
import '../features/deeplinks/screens/home_screen.dart';
import '../features/environments/screens/environment_list_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/projects/screens/projects_screen.dart';
import '../features/settings/screens/settings_screen.dart';

enum AppRoute {
  home(name: 'home', path: '/'),
  addDeeplink(name: 'add-deeplink', path: '/deeplinks/new'),
  editDeeplink(name: 'edit-deeplink', path: '/deeplinks/:id/edit'),
  favorites(name: 'favorites', path: '/favorites'),
  projects(name: 'projects', path: '/projects'),
  environments(name: 'environments', path: '/projects/:projectId/environments'),
  history(name: 'history', path: '/history'),
  settings(name: 'settings', path: '/settings');

  const AppRoute({required this.name, required this.path});

  final String name;
  final String path;
}

GoRouter createAppRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? AppRoute.home.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.history.path,
                name: AppRoute.history.name,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.favorites.path,
                name: AppRoute.favorites.name,
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.projects.path,
                name: AppRoute.projects.name,
                builder: (context, state) => const ProjectsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.addDeeplink.path,
        name: AppRoute.addDeeplink.name,
        builder: (context, state) {
          final extra = state.extra;
          final initialUrl = extra is String ? extra : null;

          return AddDeeplinkScreen(initialUrl: initialUrl);
        },
      ),
      GoRoute(
        path: AppRoute.editDeeplink.path,
        name: AppRoute.editDeeplink.name,
        builder: (context, state) {
          final deeplinkId = int.tryParse(state.pathParameters['id'] ?? '');

          return EditDeeplinkScreen(deeplinkId: deeplinkId);
        },
      ),
      GoRoute(
        path: AppRoute.environments.path,
        name: AppRoute.environments.name,
        builder: (context, state) {
          final projectId = int.tryParse(
            state.pathParameters['projectId'] ?? '',
          );

          return EnvironmentListScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

final appRouter = createAppRouter();
