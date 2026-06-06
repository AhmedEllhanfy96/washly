import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service.dart';
import 'api_client.dart';

final servicesServiceProvider = Provider<ServicesService>((ref) => ServicesService());

class ServicesService {
  final Dio _dio = createDio();

  Future<List<WashService>> fetchServices() async {
    final res = await _dio.get('/services');
    return (res.data as List)
        .map((j) => WashService.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> validatePromo(String code) async {
    final res = await _dio.post('/promos/validate', data: {'code': code});
    return res.data as Map<String, dynamic>;
  }
}
