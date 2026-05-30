import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pricing_service.dart';

final pricingServiceProvider = Provider<PricingService>((ref) => PricingService());

class PricingNotifier extends AsyncNotifier<ServicePrices> {
  @override
  Future<ServicePrices> build() =>
      ref.read(pricingServiceProvider).fetchPrices();

  // Renamed to avoid conflict with Riverpod's built-in AsyncNotifier.update()
  Future<void> savePrices({
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

  Future<void> saveContact({
    required String instapayNumber,
    required String instapayLink,
    required String supportPhone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(pricingServiceProvider).updateContactSettings(
          instapayNumber: instapayNumber,
          instapayLink: instapayLink,
          supportPhone: supportPhone,
        ));
  }
}

final pricingProvider = AsyncNotifierProvider<PricingNotifier, ServicePrices>(PricingNotifier.new);
