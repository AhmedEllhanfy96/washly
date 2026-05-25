import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pricing_service.dart';

final pricingServiceProvider = Provider<PricingService>((ref) => PricingService());

final pricingProvider = FutureProvider<ServicePrices>((ref) async {
  return ref.read(pricingServiceProvider).fetchPrices();
});
