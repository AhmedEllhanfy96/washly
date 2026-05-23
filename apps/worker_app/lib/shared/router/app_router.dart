import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/jobs/jobs_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(
      workerAuthStateProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final workerRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(workerAuthStateProvider);
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
