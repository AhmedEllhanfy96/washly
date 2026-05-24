import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_account.dart';
import '../services/api_client.dart';

final customersProvider =
    FutureProvider.autoDispose<List<CustomerAccount>>((ref) async {
  final dio = await createDio();
  final res = await dio.get<List<dynamic>>('/team/customers');
  return (res.data ?? [])
      .map((j) => CustomerAccount.fromJson(j as Map<String, dynamic>))
      .toList();
});
