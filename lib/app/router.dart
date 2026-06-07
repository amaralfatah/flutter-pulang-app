import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/test/google_drive_test_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

/// Application routes
class AppRoutes {
  static const home = '/';
  static const statistics = '/statistics';
  static const calendar = '/calendar';
  static const settings = '/settings';
  static const driveTest = '/drive-test';
}

/// GoRouter configuration
final router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.statistics,
              name: 'statistics',
              builder: (context, state) => const StatisticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              name: 'calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.driveTest,
      name: 'driveTest',
      builder: (context, state) => const GoogleDriveTestScreen(),
    ),
  ],
);
