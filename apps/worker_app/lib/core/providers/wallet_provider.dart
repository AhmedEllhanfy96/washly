import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet.dart';
import '../services/wallet_service.dart';

final myWalletProvider = FutureProvider<List<WalletEntry>>((ref) {
  return ref.read(workerWalletServiceProvider).getMyEntries();
});
