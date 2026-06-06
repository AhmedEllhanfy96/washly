import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service.dart';
import 'api_client.dart';

final adminServicesServiceProvider =
    Provider<AdminServicesService>((ref) => AdminServicesService());

class AdminServicesService {
  final Dio _dio = createDio();

  Future<List<AdminService>> fetchAll({bool includeInactive = true}) async {
    final res = await _dio.get('/services',
        queryParameters: includeInactive ? {'all': 'true'} : null);
    return (res.data as List)
        .map((j) => AdminService.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<AdminService> create({
    required String key,
    required String name,
    required String description,
    required int price,
    required List<String> features,
    String badge = '',
    String imageUrl = '',
    int sortOrder = 0,
  }) async {
    final res = await _dio.post('/services', data: {
      'key': key,
      'name': name,
      'description': description,
      'price': price,
      'features': features,
      'badge': badge,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
    });
    return AdminService.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminService> update(String id, Map<String, dynamic> fields) async {
    final res = await _dio.patch('/services/$id', data: fields);
    return AdminService.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/services/$id');
  }
}
