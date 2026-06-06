import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service.dart';
import '../services/services_service.dart';

final adminServicesProvider = FutureProvider<List<AdminService>>((ref) {
  return ref.read(adminServicesServiceProvider).fetchAll();
});
