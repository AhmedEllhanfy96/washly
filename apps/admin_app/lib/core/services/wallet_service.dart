import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet.dart';
import 'package:intl/intl.dart';
import 'api_client.dart';

final adminWalletServiceProvider = Provider<AdminWalletService>((_) => AdminWalletService());

class AdminWalletService {
  final Dio _dio = createDio();

  Future<List<WorkerWalletSummary>> getSummary() async {
    final res = await _dio.get('/wallet/summary');
    return (res.data as List)
        .map((j) => WorkerWalletSummary.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<CompanyWalletSummary> getCompanySummary() async {
    final res = await _dio.get('/wallet/company');
    return CompanyWalletSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<WalletEntry>> getWorkerEntries(String workerId) async {
    final res = await _dio.get('/wallet', queryParameters: {'workerId': workerId});
    return (res.data as List)
        .map((j) => WalletEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> settleEntry(String entryId) =>
      _dio.post('/wallet/settle/$entryId');

  Future<void> settleAll(String workerId) =>
      _dio.post('/wallet/settle-all/$workerId');

  Future<void> reconcileDay(String date) =>
      _dio.post('/wallet/company/reconcile', data: {'date': date});

  Future<int> resetCompanyWallet() async {
    final res = await _dio.post('/wallet/company/reset');
    return (res.data['deleted'] as num?)?.toInt() ?? 0;
  }

  Future<List<CompanyDayEntry>> getDayEntries(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _dio.get('/wallet/company/day', queryParameters: {'date': dateStr});
    return (res.data as List)
        .map((j) => CompanyDayEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
