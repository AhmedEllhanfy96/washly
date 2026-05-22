import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/bookings/booking_detail_screen.dart';
import '../../features/bookings/booking_list_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/team/team_screen.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(adminAuthStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLogin = state.matchedLocation == '/login';
      if (authState.isLoading) return null;
      if (!isLoggedIn && !isLogin) return '/login';
      if (isLoggedIn && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const AdminLoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'bookings',
            builder: (_, __) => const BookingListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    BookingDetailScreen(bookingId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: 'team', builder: (_, __) => const TeamScreen()),
        ],
      ),
    ],
  );
});
