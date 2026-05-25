import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/booking/booking_flow_screen.dart';
import '../../features/booking/booking_success_screen.dart';
import '../../features/history/booking_history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../widgets/main_shell.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;
      final isLoggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/reset-password';
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // ── Auth (outside shell, no bottom nav) ───────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),

      // ── Main shell with bottom navigation ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(shell: shell),
        branches: [
          // Tab 0 — Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(
                    path: 'book', builder: (_, __) => const BookingFlowScreen()),
                GoRoute(
                    path: 'success',
                    builder: (_, __) => const BookingSuccessScreen()),
              ],
            ),
          ]),

          // Tab 1 — My Bookings
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/history',
                builder: (_, __) => const BookingHistoryScreen()),
          ]),

          // Tab 2 — Profile
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
