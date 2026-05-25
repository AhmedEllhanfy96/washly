import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pricing_service.dart';

final pricingServiceProvider = Provider<PricingService>((ref) => PricingService());

class PricingNotifier extends AsyncNotifier<ServicePrices> {
  @override
  Future<ServicePrices> build() =>
      ref.read(pricingServiceProvider).fetchPrices();

  Future<void> update({
    required int exteriorOnly,
    required int interiorOnly,
    required int fullService,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(pricingServiceProvider).updatePrices(
          exteriorOnly: exteriorOnly,
          interiorOnly: interiorOnly,
          fullService: fullService,
        ));
  }
}

final pricingProvider = AsyncNotifierProvider<PricingNotifier, ServicePrices>(PricingNotifier.new);
