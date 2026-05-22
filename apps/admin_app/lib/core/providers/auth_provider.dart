import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/ws_service.dart';

class AdminAuthNotifier extends StateNotifier<AsyncValue<AdminUserProfile?>> {
  AdminAuthNotifier(this._svc, this._ws) : super(const AsyncValue.loading()) {
    _init();
  }

  final AdminAuthService _svc;
  final WsService _ws;

  Future<void> _init() async {
    final user = await _svc.init();
    state = AsyncValue.data(user);
    if (user != null) await _ws.connect();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _svc.signIn(email: email, password: password);
      state = AsyncValue.data(_svc.currentUser);
      await _ws.connect();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    _ws.disconnect();
    await _svc.signOut();
    state = const AsyncValue.data(null);
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AsyncValue<AdminUserProfile?>>((ref) {
  return AdminAuthNotifier(ref.read(adminAuthServiceProvider), ref.read(wsServiceProvider));
});

// Alias for router compatibility
final adminAuthStateProvider = Provider<AsyncValue<AdminUserProfile?>>((ref) {
  return ref.watch(adminAuthProvider);
});
