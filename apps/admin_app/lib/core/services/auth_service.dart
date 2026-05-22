import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) => AdminAuthService());

class AdminUserProfile {
  final String id;
  final String email;
  final String name;
  final String role;
  const AdminUserProfile({required this.id, required this.email, required this.name, required this.role});
  factory AdminUserProfile.fromJson(Map<String, dynamic> json) => AdminUserProfile(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'customer',
      );
}

class AdminAuthService {
  final Dio _dio = createDio();
  final _storage = const FlutterSecureStorage();
  AdminUserProfile? _currentUser;

  AdminUserProfile? get currentUser => _currentUser;

  Future<AdminUserProfile?> init() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;
    try {
      final res = await _dio.get('/auth/me');
      final user = AdminUserProfile.fromJson(res.data as Map<String, dynamic>);
      if (user.role != 'admin') {
        await _storage.delete(key: 'auth_token');
        return null;
      }
      _currentUser = user;
      return _currentUser;
    } catch (_) {
      await _storage.delete(key: 'auth_token');
      return null;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    final user = AdminUserProfile.fromJson(res.data['user'] as Map<String, dynamic>);
    if (user.role != 'admin') {
      throw Exception('Access denied. This account does not have admin privileges.');
    }
    await _storage.write(key: 'auth_token', value: res.data['token'] as String);
    _currentUser = user;
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'auth_token');
    _currentUser = null;
  }
}
