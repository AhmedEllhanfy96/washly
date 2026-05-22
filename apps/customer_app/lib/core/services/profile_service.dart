import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_car.dart';
import '../models/saved_location.dart';
import 'api_client.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

class ProfileService {
  final Dio _dio = createDio();

  Future<List<SavedCar>> getSavedCars() async {
    final res = await _dio.get('/profile/cars');
    return (res.data as List)
        .map((j) => SavedCar.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<SavedCar> saveCar({
    required String make,
    required String model,
    required String color,
    required String plateNumber,
    String? year,
  }) async {
    final res = await _dio.post('/profile/cars', data: {
      'make': make,
      'model': model,
      'color': color,
      'plateNumber': plateNumber,
      'year': year,
    });
    return SavedCar.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteCar(String id) => _dio.delete('/profile/cars/$id');

  Future<List<SavedLocation>> getSavedLocations() async {
    final res = await _dio.get('/profile/locations');
    return (res.data as List)
        .map((j) => SavedLocation.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<SavedLocation> saveLocation({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final res = await _dio.post('/profile/locations', data: {
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });
    return SavedLocation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteLocation(String id) => _dio.delete('/profile/locations/$id');
}
