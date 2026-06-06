import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/promos_service.dart';

final adminPromosProvider = FutureProvider<List<AdminPromo>>((ref) {
  return ref.read(adminPromosServiceProvider).fetchAll();
});
