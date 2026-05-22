import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

final workerAuthServiceProvider = Provider<WorkerAuthService>((ref) => WorkerAuthService());

class WorkerProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  const WorkerProfile({required this.id, required this.name, required this.email, required this.role});
  factory WorkerProfile.fromJson(Map<String, dynamic> json) => WorkerProfile(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'worker',
      );
}

class WorkerAuthService {
  final Dio _dio = createDio();
  final _storage = const FlutterSecureStorage();
  WorkerProfile? _currentUser;

  WorkerProfile? get currentUser => _currentUser;

  Future<WorkerProfile?> init() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;
    try {
      final res = await _dio.get('/auth/me');
      final user = WorkerProfile.fromJson(res.data as Map<String, dynamic>);
      if (user.role != 'worker') {
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
    final user = WorkerProfile.fromJson(res.data['user'] as Map<String, dynamic>);
    if (user.role != 'worker') {
      throw Exception('This account is not a worker account.');
    }
    await _storage.write(key: 'auth_token', value: res.data['token'] as String);
    _currentUser = user;
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'auth_token');
    _currentUser = null;
  }
}
