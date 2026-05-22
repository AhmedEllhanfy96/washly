import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/jobs/jobs_screen.dart';

final workerRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(workerAuthStateProvider);

  return GoRouter(
    initialLocation: '/jobs',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final isLoggedIn = authState.valueOrNull != null;
      final isLogin = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLogin) return '/login';
      if (isLoggedIn && isLogin) return '/jobs';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const WorkerLoginScreen()),
      GoRoute(path: '/jobs', builder: (_, __) => const JobsScreen()),
    ],
  );
});
