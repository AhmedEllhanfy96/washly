import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final Dio _dio = createDio();
  UserProfile? _currentUser;

  UserProfile? get currentUser => _currentUser;

  Future<UserProfile?> init() async {
    final token = await readPref('auth_token');
    if (token == null) return null;
    try {
      final res = await _dio.get('/auth/me');
      _currentUser = UserProfile.fromJson(res.data as Map<String, dynamic>);
      return _currentUser;
    } catch (_) {
      await deletePref('auth_token');
      return null;
    }
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      await writePref('auth_token', res.data['token'] as String);
      _currentUser = UserProfile.fromJson(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] as String?
          ?? 'Login failed. Check your connection.';
      throw Exception(msg);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone ?? '',
      });
      await writePref('auth_token', res.data['token'] as String);
      _currentUser = UserProfile.fromJson(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] as String?
          ?? 'Registration failed. Check your connection.';
      throw Exception(msg);
    }
  }

  Future<void> signOut() async {
    await deletePref('auth_token');
    _currentUser = null;
  }
}
