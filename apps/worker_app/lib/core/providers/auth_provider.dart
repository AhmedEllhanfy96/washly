import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/ws_service.dart';

class WorkerAuthNotifier extends StateNotifier<AsyncValue<WorkerProfile?>> {
  WorkerAuthNotifier(this._svc, this._ws, this._loc) : super(const AsyncValue.loading()) {
    _init();
  }

  final WorkerAuthService _svc;
  final WsService _ws;
  final LocationService _loc;

  Future<void> _init() async {
    final user = await _svc.init();
    state = AsyncValue.data(user);
    if (user != null) {
      await _ws.connect();
      await _loc.start();
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _svc.signIn(email: email, password: password);
      state = AsyncValue.data(_svc.currentUser);
      await _ws.connect();
      await _loc.start();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _loc.stop();
    _ws.disconnect();
    await _svc.signOut();
    state = const AsyncValue.data(null);
  }
}

final workerAuthProvider =
    StateNotifierProvider<WorkerAuthNotifier, AsyncValue<WorkerProfile?>>((ref) {
  return WorkerAuthNotifier(
    ref.read(workerAuthServiceProvider),
    ref.read(wsServiceProvider),
    ref.read(locationServiceProvider),
  );
});

final workerAuthStateProvider = Provider<AsyncValue<WorkerProfile?>>((ref) {
  return ref.watch(workerAuthProvider);
});
