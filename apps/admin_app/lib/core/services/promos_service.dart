import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final adminPromosServiceProvider =
    Provider<AdminPromosService>((ref) => AdminPromosService());

class AdminPromo {
  final String id;
  final String code;
  final int discountPercent;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final int? maxUses;
  final int? maxUsesPerUser;
  final int usedCount;

  const AdminPromo({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
    this.maxUses,
    this.maxUsesPerUser,
    required this.usedCount,
  });

  factory AdminPromo.fromJson(Map<String, dynamic> json) => AdminPromo(
        id: json['id'] as String,
        code: json['code'] as String,
        discountPercent: (json['discountPercent'] as num).toInt(),
        validFrom: DateTime.parse(json['validFrom'] as String),
        validUntil: DateTime.parse(json['validUntil'] as String),
        isActive: json['isActive'] as bool? ?? true,
        maxUses: (json['maxUses'] as num?)?.toInt(),
        maxUsesPerUser: (json['maxUsesPerUser'] as num?)?.toInt(),
        usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      );
}

class AdminPromosService {
  final Dio _dio = createDio();

  Future<List<AdminPromo>> fetchAll() async {
    final res = await _dio.get('/promos');
    return (res.data as List)
        .map((j) => AdminPromo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<AdminPromo> create({
    required String code,
    required int discountPercent,
    required DateTime validUntil,
    int? maxUses,
    int? maxUsesPerUser,
  }) async {
    final res = await _dio.post('/promos', data: {
      'code': code,
      'discountPercent': discountPercent,
      'validUntil': validUntil.toIso8601String(),
      if (maxUses != null) 'maxUses': maxUses,
      if (maxUsesPerUser != null) 'maxUsesPerUser': maxUsesPerUser,
    });
    return AdminPromo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminPromo> update(String id, {bool? isActive, DateTime? validUntil, int? maxUses, int? maxUsesPerUser}) async {
    final res = await _dio.patch('/promos/$id', data: {
      if (isActive != null) 'isActive': isActive,
      if (validUntil != null) 'validUntil': validUntil.toIso8601String(),
      if (maxUses != null) 'maxUses': maxUses,
      if (maxUsesPerUser != null) 'maxUsesPerUser': maxUsesPerUser,
    });
    return AdminPromo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/promos/$id');
  }
}
