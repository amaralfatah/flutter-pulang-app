import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/qadha/qadha_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/qibla/qibla_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

/// Application routes
class AppRoutes {
  static const home = '/';
  static const history = '/history';
  static const qadha = '/qadha';
  static const qibla = '/qibla';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
}

/// Diset sekali dari `main()` (setelah SharedPreferences terbaca) sebelum
/// [router] dipakai, jadi [redirect] di bawah bisa memutuskan secara sinkron
/// tanpa GoRouter perlu menunggu operasi async.
bool onboardingCompleted = true;

/// GoRouter configuration
///
/// Bottom nav hanya memuat tiga tujuan yang benar-benar dikunjungi harian.
/// Kiblat dan Pengaturan didorong sebagai halaman penuh dari Home: keduanya
/// alat sesekali, bukan tempat yang perlu selalu tersedia satu ketukan.
final router = GoRouter(
  initialLocation: AppRoutes.home,
  redirect: (context, state) {
    final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
    if (!onboardingCompleted && !atOnboarding) return AppRoutes.onboarding;
    if (onboardingCompleted && atOnboarding) return AppRoutes.home;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
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
              path: AppRoutes.history,
              name: 'history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.qadha,
              name: 'qadha',
              builder: (context, state) => const QadhaScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.qibla,
      name: 'qibla',
      builder: (context, state) => const QiblaScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
