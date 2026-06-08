import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/slide.dart';
import '../services/api_client.dart';

final slidesProvider = FutureProvider<List<Slide>>((ref) async {
  final dio = createDio();
  try {
    final res = await dio.get('/slides');
    return (res.data as List)
        .map((j) => Slide.fromJson(j as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
