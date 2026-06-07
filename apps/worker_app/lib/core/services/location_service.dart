import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'api_client.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class LocationService {
  final Dio _dio = createDio();
  Timer? _timer;
  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _requestPermission();
    await _send(); // immediate first send
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _send());
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _requestPermission() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    if (!_running) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await _dio.post('/team/workers/me/location', data: {
        'lat': pos.latitude,
        'lng': pos.longitude,
      });
    } catch (_) {}
  }
}
