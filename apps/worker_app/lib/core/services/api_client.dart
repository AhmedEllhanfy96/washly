import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _port = 3000;

// Default: Android emulator → host machine localhost
const defaultServerUrl = 'http://10.0.2.2:$_port';

Future<String> getApiUrl() async =>
    await _storage.read(key: 'server_url') ?? defaultServerUrl;

Future<String> getWsUrl() async {
  final api = await getApiUrl();
  return api
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://') +
      '/ws';
}

Future<void> saveServerUrl(String url) async {
  final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
  await _storage.write(key: 'server_url', value: clean);
}

/// Scans every host on the device's own /24 subnet in parallel.
/// Returns the first URL that responds to GET /health, or null.
Future<String?> discoverServer({void Function(int done, int total)? onProgress}) async {
  // Collect all IPv4 subnets this device is on
  final subnets = <String>{};
  try {
    final interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length == 4) {
          subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    }
  } catch (_) {}

  if (subnets.isEmpty) return null;

  final candidates = <String>[];
  for (final subnet in subnets) {
    for (int i = 1; i <= 254; i++) {
      candidates.add('http://$subnet.$i:$_port');
    }
  }

  // Also try emulator alias and localhost in case we're on desktop/web
  candidates.insertAll(0, [
    'http://10.0.2.2:$_port',
    'http://localhost:$_port',
    'http://127.0.0.1:$_port',
  ]);

  final total = candidates.length;
  int done = 0;

  // Probe in batches of 30 so we don't flood the network
  const batchSize = 30;
  for (int i = 0; i < candidates.length; i += batchSize) {
    final batch = candidates.skip(i).take(batchSize).toList();
    final results = await Future.wait(batch.map((url) async {
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(milliseconds: 800),
          receiveTimeout: const Duration(milliseconds: 800),
        ));
        final res = await dio.get('$url/health');
        if (res.statusCode == 200) return url;
      } catch (_) {}
      return null;
    }));
    done += batch.length;
    onProgress?.call(done, total);
    final found = results.firstWhere((r) => r != null, orElse: () => null);
    if (found != null) return found;
  }
  return null;
}

Dio createDio() {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      options.baseUrl = await getApiUrl();
      final token = await _storage.read(key: 'auth_token');
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
  ));
  return dio;
}
