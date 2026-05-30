import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet.dart';
import 'api_client.dart';

final workerWalletServiceProvider =
    Provider<WorkerWalletService>((_) => WorkerWalletService());

class WorkerWalletService {
  final Dio _dio = createDio();

  Future<List<WalletEntry>> getMyEntries() async {
    final res = await _dio.get('/wallet');
    return (res.data as List)
        .map((j) => WalletEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
