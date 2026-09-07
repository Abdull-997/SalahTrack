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
  final bool onboardingComplete =
      ref.read(initialPreferencesProvider).onboardingComplete;
  return GoRouter(
    initialLocation: onboardingComplete ? '/home' : '/onboarding',
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/tracker',
            builder: (context, state) => const TrackerScreen(),
          ),
          GoRoute(
            path: '/qibla',
            builder: (context, state) => const QiblaScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/reminder/:prayerId',
        builder: (context, state) => PrayerReminderScreen(
          prayerId: state.pathParameters['prayerId']!,
        ),
      ),
    ],
  );
});
