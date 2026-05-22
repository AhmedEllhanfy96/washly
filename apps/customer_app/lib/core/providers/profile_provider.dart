import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_car.dart';
import '../models/saved_location.dart';
import '../services/profile_service.dart';

final savedCarsProvider = FutureProvider<List<SavedCar>>((ref) {
  return ref.read(profileServiceProvider).getSavedCars();
});

final savedLocationsProvider = FutureProvider<List<SavedLocation>>((ref) {
  return ref.read(profileServiceProvider).getSavedLocations();
});
