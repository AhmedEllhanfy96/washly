import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';

class ServicePrices {
  final int exteriorOnly;
  final int interiorOnly;
  final int fullService;

  const ServicePrices({
    required this.exteriorOnly,
    required this.interiorOnly,
    required this.fullService,
  });

  static const defaults = ServicePrices(
    exteriorOnly: AppConfig.priceExteriorOnly,
    interiorOnly: AppConfig.priceInteriorOnly,
    fullService: AppConfig.priceFullService,
  );
}

class PricingService {
  final Dio _dio = createDio();

  Future<ServicePrices> fetchPrices() async {
    try {
      final res = await _dio.get('/settings');
      final data = res.data as Map<String, dynamic>;
      return ServicePrices(
        exteriorOnly: int.tryParse(data['price_exterior_only']?.toString() ?? '') ??
            AppConfig.priceExteriorOnly,
        interiorOnly: int.tryParse(data['price_interior_only']?.toString() ?? '') ??
            AppConfig.priceInteriorOnly,
        fullService: int.tryParse(data['price_full_service']?.toString() ?? '') ??
            AppConfig.priceFullService,
      );
    } catch (_) {
      return ServicePrices.defaults;
    }
  }

  Future<ServicePrices> updatePrices({
    required int exteriorOnly,
    required int interiorOnly,
    required int fullService,
  }) async {
    final res = await _dio.put('/settings', data: {
      'price_exterior_only': exteriorOnly,
      'price_interior_only': interiorOnly,
      'price_full_service': fullService,
    });
    final data = res.data as Map<String, dynamic>;
    return ServicePrices(
      exteriorOnly: int.tryParse(data['price_exterior_only']?.toString() ?? '') ?? exteriorOnly,
      interiorOnly: int.tryParse(data['price_interior_only']?.toString() ?? '') ?? interiorOnly,
      fullService: int.tryParse(data['price_full_service']?.toString() ?? '') ?? fullService,
    );
  }
}
