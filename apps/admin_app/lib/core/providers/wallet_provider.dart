import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet.dart';
import '../services/wallet_service.dart';

final walletSummaryProvider = FutureProvider<List<WorkerWalletSummary>>((ref) {
  return ref.read(adminWalletServiceProvider).getSummary();
});

final companyWalletProvider = FutureProvider<CompanyWalletSummary>((ref) {
  return ref.read(adminWalletServiceProvider).getCompanySummary();
});

final workerEntriesProvider =
    FutureProvider.family<List<WalletEntry>, String>((ref, workerId) {
  return ref.read(adminWalletServiceProvider).getWorkerEntries(workerId);
});

final companyDayEntriesProvider =
    FutureProvider.family<List<CompanyDayEntry>, DateTime>((ref, date) {
  return ref.read(adminWalletServiceProvider).getDayEntries(date);
});
