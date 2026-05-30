import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/wallet.dart';
import '../../core/providers/wallet_provider.dart';

class WorkerWalletScreen extends ConsumerWidget {
  const WorkerWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(myWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myWalletProvider),
          ),
        ],
      ),
      body: entries.when(
        data: (list) {
          // Wallet only contains cash entries — money collected from customers
          final pending = list.where((e) => e.isPending).toList();
          final totalPending = pending.fold(0, (s, e) => s + e.amount);

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No transactions yet',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Cash jobs you complete will appear here',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            );
          }

          // Group ALL entries by date for the day-by-day view
          final byDate = <String, List<WalletEntry>>{};
          for (final e in list) {
            final key = DateFormat('yyyy-MM-dd').format(e.createdAt);
            byDate.putIfAbsent(key, () => []).add(e);
          }
          final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myWalletProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── To hand over banner ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: totalPending > 0
                          ? [Colors.orange[700]!, Colors.orange[500]!]
                          : [Colors.green[600]!, Colors.green[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        totalPending > 0
                            ? Icons.payments_outlined
                            : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              totalPending > 0
                                  ? 'Hand over to admin'
                                  : 'All settled!',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '$totalPending EGP',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (pending.isNotEmpty)
                              Text(
                                '${pending.length} cash job${pending.length > 1 ? 's' : ''} pending',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Day-by-day entries ───────────────────────────────────
                for (final dateKey in dates) ...[
                  _DateHeader(dateKey: dateKey),
                  const SizedBox(height: 4),
                  ...byDate[dateKey]!.map((e) => _EntryCard(entry: e)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String dateKey; // yyyy-MM-dd
  const _DateHeader({required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateKey);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final label = isToday ? 'Today' : DateFormat('EEE, MMM d').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: isToday ? Colors.orange : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.orange[700] : Colors.grey[500])),
      ]),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final WalletEntry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d • h:mm a');
    final isPending = entry.isPending;
    final color = isPending ? Colors.orange[700]! : Colors.grey[400]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isPending ? 1 : 0,
      color: isPending ? Colors.white : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending ? Colors.orange.withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.payments_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.customerName ?? 'Customer',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(_serviceName(entry.serviceType),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  if (entry.scheduledAt != null)
                    Text(dateFmt.format(entry.scheduledAt!),
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.amount} EGP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.orange[700] : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending ? 'Hand to admin' : 'Done ✓',
                  style: TextStyle(
                    fontSize: 10,
                    color: isPending ? Colors.orange[700] : Colors.grey,
                    fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _serviceName(String? t) => switch (t) {
        'fullService' => 'Full Service',
        'interiorOnly' => 'Interior Only',
        _ => 'Exterior Only',
      };
}
