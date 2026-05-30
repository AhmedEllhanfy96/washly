import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';

class ServicePrices {
  final int exteriorOnly;
  final int interiorOnly;
  final int fullService;
  final String instapayNumber;
  final String instapayLink;
  final String supportPhone;

  const ServicePrices({
    required this.exteriorOnly,
    required this.interiorOnly,
    required this.fullService,
    this.instapayNumber = '',
    this.instapayLink = '',
    this.supportPhone = '',
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
      String _str(String key) {
        final v = data[key];
        if (v == null) return '';
        final s = v.toString().replaceAll('"', '');
        return s == 'null' ? '' : s;
      }
      return ServicePrices(
        exteriorOnly: int.tryParse(_str('price_exterior_only')) ??
            AppConfig.priceExteriorOnly,
        interiorOnly: int.tryParse(_str('price_interior_only')) ??
            AppConfig.priceInteriorOnly,
        fullService: int.tryParse(_str('price_full_service')) ??
            AppConfig.priceFullService,
        instapayNumber: _str('instapay_number'),
        instapayLink:   _str('instapay_link'),
        supportPhone:   _str('support_phone'),
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
    String _str(String key) {
      final v = data[key];
      if (v == null) return '';
      final s = v.toString().replaceAll('"', '');
      return s == 'null' ? '' : s;
    }
    return ServicePrices(
      exteriorOnly: int.tryParse(_str('price_exterior_only')) ?? exteriorOnly,
      interiorOnly: int.tryParse(_str('price_interior_only')) ?? interiorOnly,
      fullService: int.tryParse(_str('price_full_service')) ?? fullService,
      instapayNumber: _str('instapay_number'),
      instapayLink:   _str('instapay_link'),
      supportPhone:   _str('support_phone'),
    );
  }

  Future<ServicePrices> updateContactSettings({
    required String instapayNumber,
    required String instapayLink,
    required String supportPhone,
  }) async {
    final res = await _dio.put('/settings', data: {
      'instapay_number': instapayNumber,
      'instapay_link':   instapayLink,
      'support_phone':   supportPhone,
    });
    final data = res.data as Map<String, dynamic>;
    String _str(String key) {
      final v = data[key];
      if (v == null) return '';
      final s = v.toString().replaceAll('"', '');
      return s == 'null' ? '' : s;
    }
    return ServicePrices(
      exteriorOnly: int.tryParse(_str('price_exterior_only')) ??
          AppConfig.priceExteriorOnly,
      interiorOnly: int.tryParse(_str('price_interior_only')) ??
          AppConfig.priceInteriorOnly,
      fullService: int.tryParse(_str('price_full_service')) ??
          AppConfig.priceFullService,
      instapayNumber: _str('instapay_number'),
      instapayLink:   _str('instapay_link'),
      supportPhone:   _str('support_phone'),
    );
  }
}
