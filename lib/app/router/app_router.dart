import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salah_focus/features/onboarding/presentation/onboarding_screen.dart';
import 'package:salah_focus/features/prayer_times/presentation/prayer_reminder_screen.dart';
import 'package:salah_focus/features/prayer_times/presentation/home_screen.dart';
import 'package:salah_focus/features/prayer_tracker/presentation/tracker_screen.dart';
import 'package:salah_focus/features/qibla/presentation/qibla_screen.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';
import 'package:salah_focus/shared/widgets/main_shell.dart';

final Provider<GoRouter> goRouterProvider = Provider<GoRouter>((Ref ref) {
  final bool onboardingComplete = ref
      .read(initialPreferencesProvider)
      .onboardingComplete;
  return GoRouter(
    initialLocation: onboardingComplete ? '/home' : '/onboarding',
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/tracker',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const TrackerScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/qibla',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const QiblaScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/reminder/:prayerId',
        builder: (context, state) =>
            PrayerReminderScreen(prayerId: state.pathParameters['prayerId']!),
      ),
    ],
  );
});
