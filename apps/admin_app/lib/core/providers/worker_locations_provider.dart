import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/worker_location.dart';
import '../services/api_client.dart';
import '../services/ws_service.dart';

class WorkerLocationsNotifier extends StateNotifier<Map<String, WorkerLocation>> {
  WorkerLocationsNotifier(this._ws) : super({}) {
    _fetchAll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchAll());
    _wsSub = _ws.events.listen(_onWsEvent);
  }

  final WsService _ws;
  final Dio _dio = createDio();
  Timer? _timer;
  StreamSubscription? _wsSub;

  Future<void> _fetchAll() async {
    try {
      final res = await _dio.get('/team/workers/locations');
      final list = (res.data as List)
          .map((j) => WorkerLocation.fromJson(j as Map<String, dynamic>))
          .toList();
      state = { for (final w in list) w.workerId: w };
    } catch (_) {}
  }

  void _onWsEvent(Map<String, dynamic> event) {
    if (event['type'] != 'worker_location') return;
    try {
      final loc = WorkerLocation.fromJson(event as Map<String, dynamic>);
      state = { ...state, loc.workerId: loc };
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }
}

final workerLocationsProvider =
    StateNotifierProvider.autoDispose<WorkerLocationsNotifier, Map<String, WorkerLocation>>(
  (ref) => WorkerLocationsNotifier(ref.read(wsServiceProvider)),
);
