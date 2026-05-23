import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

class WorkerAuthNotifier extends StateNotifier<AsyncValue<WorkerProfile?>> {
  WorkerAuthNotifier(this._svc) : super(const AsyncValue.loading()) {
    _init();
  }

  final WorkerAuthService _svc;

  Future<void> _init() async {
    final user = await _svc.init();
    state = AsyncValue.data(user);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _svc.signIn(email: email, password: password);
      state = AsyncValue.data(_svc.currentUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _svc.signOut();
    state = const AsyncValue.data(null);
  }
}

final workerAuthProvider =
    StateNotifierProvider<WorkerAuthNotifier, AsyncValue<WorkerProfile?>>((ref) {
  return WorkerAuthNotifier(ref.read(workerAuthServiceProvider));
});

final workerAuthStateProvider = Provider<AsyncValue<WorkerProfile?>>((ref) {
  return ref.watch(workerAuthProvider);
});
