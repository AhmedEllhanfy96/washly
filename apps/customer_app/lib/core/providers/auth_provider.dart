import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/ws_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthNotifier(this._svc, this._ws) : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthService _svc;
  final WsService _ws;

  Future<void> _init() async {
    final user = await _svc.init();
    state = AsyncValue.data(user);
    if (user != null) await _ws.connect();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _svc.signInWithEmail(email: email, password: password);
      state = AsyncValue.data(_svc.currentUser);
      await _ws.connect();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name, String? phone) async {
    state = const AsyncValue.loading();
    try {
      await _svc.signUpWithEmail(email: email, password: password, name: name, phone: phone);
      state = AsyncValue.data(_svc.currentUser);
      await _ws.connect();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _ws.disconnect();
    await _svc.signOut();
    state = const AsyncValue.data(null);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref.read(wsServiceProvider));
});

// Alias kept for router compatibility
final authStateProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  return ref.watch(authProvider);
});
