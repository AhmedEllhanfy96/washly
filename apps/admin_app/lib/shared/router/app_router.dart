import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/bookings/booking_detail_screen.dart';
import '../../features/bookings/booking_list_screen.dart';
import '../../features/bookings/create_booking_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/schedule/schedule_screen.dart';
import '../../features/settings/pricing_screen.dart';
import '../../features/team/team_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(
      adminAuthStateProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(adminAuthStateProvider);
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
                path: 'new',
                builder: (_, __) => const CreateBookingScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    BookingDetailScreen(bookingId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: 'team', builder: (_, __) => const TeamScreen()),
          GoRoute(path: 'customers', builder: (_, __) => const CustomersScreen()),
          GoRoute(path: 'schedule', builder: (_, __) => const ScheduleScreen()),
          GoRoute(path: 'pricing', builder: (_, __) => const PricingScreen()),
        ],
      ),
    ],
  );
});
