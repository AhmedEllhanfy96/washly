import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

// Default: Android emulator → host machine localhost
const defaultServerUrl = 'http://10.0.2.2:3000';

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
