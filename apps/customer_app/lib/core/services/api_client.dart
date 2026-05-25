import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

SharedPreferences? _prefsCache;

Future<SharedPreferences> _getPrefs() async =>
    _prefsCache ??= await SharedPreferences.getInstance();

Future<String?> readPref(String key) async =>
    (await _getPrefs()).getString(key);

Future<void> writePref(String key, String value) async =>
    (await _getPrefs()).setString(key, value);

Future<void> deletePref(String key) async =>
    (await _getPrefs()).remove(key);

const defaultServerUrl = AppConfig.defaultApiUrl;

Future<String> getApiUrl() async => defaultServerUrl;

Future<String> getWsUrl() async => defaultServerUrl
    .replaceFirst('https://', 'wss://')
    .replaceFirst('http://', 'ws://') +
    '/ws';

Dio createDio() {
  final dio = Dio(BaseOptions(
    connectTimeout: AppConfig.apiConnectTimeout,
    receiveTimeout: AppConfig.apiReceiveTimeout,
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      options.baseUrl = await getApiUrl();
      final token = await readPref('auth_token');
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
  ));
  return dio;
}
