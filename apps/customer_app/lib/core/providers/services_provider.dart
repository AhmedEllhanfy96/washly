import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service.dart';
import '../services/services_service.dart';

// autoDispose ensures a fresh fetch every time the booking flow starts
final servicesProvider = FutureProvider.autoDispose<List<WashService>>((ref) {
  return ref.read(servicesServiceProvider).fetchServices();
});
