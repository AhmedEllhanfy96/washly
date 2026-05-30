import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/wallet.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/wallet_service.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(companyWalletProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(companyWalletProvider);
    final workers = ref.watch(walletSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Company Wallet ─────────────────────────────────────────
            company.when(
              data: (c) => _CompanySection(
                summary: c,
                onRefresh: () => _refresh(ref),
              ),
              loading: () => const _CompanyCardSkeleton(),
              error: (_, __) => const _CompanyCardSkeleton(),
            ),

            const SizedBox(height: 20),

            // ── Worker Cash Collections ────────────────────────────────
            Row(children: [
              const Icon(Icons.group, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Cash to Collect from Workers',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[800])),
            ]),
            const SizedBox(height: 10),

            workers.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No workers yet',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return Column(
                  children: list
                      .map((w) => _WorkerCard(summary: w, onRefresh: () => _refresh(ref)))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Company section: totals card + daily breakdown ────────────────────────────

class _CompanySection extends ConsumerStatefulWidget {
  final CompanyWalletSummary summary;
  final VoidCallback onRefresh;
  const _CompanySection({required this.summary, required this.onRefresh});

  @override
  ConsumerState<_CompanySection> createState() => _CompanySectionState();
}

class _CompanySectionState extends ConsumerState<_CompanySection> {
  bool _resetting = false;

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Company Wallet'),
        content: const Text(
          'This will delete all company wallet entries and zero the balance. '
          'Use this after you have accounted for all revenue. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resetting = true);
    try {
      final deleted = await ref.read(adminWalletServiceProvider).resetCompanyWallet();
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Wallet reset — $deleted entries cleared'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to reset: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  void _showDayDetail(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grand total card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.account_balance, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                const Text('Company Wallet',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today: ${summary.todayTotal} EGP',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                '${summary.grandTotal} EGP',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _SourceChip(label: 'InstaPay', amount: summary.fromInstapay, icon: Icons.mobile_friendly),
                  _SourceChip(label: 'Cash', amount: summary.fromCash, icon: Icons.payments_outlined),
                  if (summary.fromCreditCard > 0)
                    _SourceChip(label: 'Card', amount: summary.fromCreditCard, icon: Icons.credit_card),
                ],
              ),
              Row(children: [
                const Spacer(),
                GestureDetector(
                  onTap: _resetting ? null : _confirmReset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _resetting
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.restart_alt, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Reset',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ]),
                  ),
                ),
              ]),
            ],
          ),
        ),

        // Daily breakdown — always visible
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Text('Daily Breakdown',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[800])),
        ]),
        const SizedBox(height: 8),
        if (summary.daily.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              'No revenue recorded yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          )
        else
          ...summary.daily.map((d) => _DayRow(
                day: d,
                onTap: () => _showDayDetail(context, d.date),
                onReconcile: () async {
                  try {
                    final dateFmt = DateFormat('yyyy-MM-dd');
                    await ref
                        .read(adminWalletServiceProvider)
                        .reconcileDay(dateFmt.format(d.date));
                    widget.onRefresh();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  }
                },
              )),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final DailyWalletEntry day;
  final VoidCallback onTap;
  final VoidCallback onReconcile;
  const _DayRow({required this.day, required this.onTap, required this.onReconcile});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    final label = isToday ? 'Today' : DateFormat('EEE, MMM d').format(day.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: day.reconciled ? Colors.grey[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: day.reconciled
              ? Colors.grey[200]!
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isToday ? Colors.green[700] : Colors.grey[800],
                      ),
                    ),
                    if (day.reconciled) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle, size: 13, color: Colors.grey[400]),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Wrap(spacing: 6, children: [
                    if (day.fromInstapay > 0)
                      Text('IP: ${day.fromInstapay}',
                          style: const TextStyle(fontSize: 11, color: Colors.blue)),
                    if (day.fromCash > 0)
                      Text('Cash: ${day.fromCash}',
                          style: TextStyle(fontSize: 11, color: Colors.orange[700])),
                    if (day.fromCreditCard > 0)
                      Text('Card: ${day.fromCreditCard}',
                          style: const TextStyle(fontSize: 11, color: Colors.purple)),
                    Text('· tap for details',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ]),
                ],
              ),
            ),
            Text(
              '${day.total} EGP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: day.reconciled ? Colors.grey[400] : Colors.green[700],
              ),
            ),
            if (!day.reconciled) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onReconcile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Settle',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  const _SourceChip({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 5),
        Text('$label: $amount EGP',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}

class _CompanyCardSkeleton extends StatelessWidget {
  const _CompanyCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ── Worker card ───────────────────────────────────────────────────────────────

class _WorkerCard extends ConsumerStatefulWidget {
  final WorkerWalletSummary summary;
  final VoidCallback onRefresh;
  const _WorkerCard({required this.summary, required this.onRefresh});

  @override
  ConsumerState<_WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends ConsumerState<_WorkerCard> {
  bool _settling = false;

  Future<void> _settleAll() async {
    setState(() => _settling = true);
    try {
      await ref.read(adminWalletServiceProvider).settleAll(widget.summary.workerId);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Collected from ${widget.summary.workerName}'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to settle'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final hasPending = s.pendingCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: hasPending ? 2 : 0,
      color: hasPending ? Colors.white : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasPending
              ? Colors.orange.withOpacity(0.4)
              : Colors.grey[200]!,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (hasPending ? Colors.orange : Colors.grey)
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    s.workerName.isNotEmpty
                        ? s.workerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: hasPending
                            ? Colors.orange[700]
                            : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.workerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    if (s.workerPhone.isNotEmpty)
                      Text(s.workerPhone,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 11)),
                    if (hasPending)
                      Text(
                          '${s.pendingCount} job${s.pendingCount > 1 ? 's' : ''} · tap to view',
                          style:
                              TextStyle(color: Colors.orange[700], fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${s.totalPending} EGP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasPending ? Colors.orange[700] : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasPending)
                    _settling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : GestureDetector(
                            onTap: _settleAll,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Collected',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                  else
                    Text('All clear · tap to view history',
                        style: TextStyle(
                            color: Colors.green[600], fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkerDetailSheet(
        summary: widget.summary,
        onRefresh: widget.onRefresh,
      ),
    );
  }
}

// ── Worker detail bottom sheet ────────────────────────────────────────────────

class _WorkerDetailSheet extends ConsumerWidget {
  final WorkerWalletSummary summary;
  final VoidCallback onRefresh;
  const _WorkerDetailSheet({required this.summary, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(workerEntriesProvider(summary.workerId));

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(summary.workerName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${summary.totalPending} EGP pending cash',
                            style: TextStyle(
                                color: summary.totalPending > 0
                                    ? Colors.orange[700]
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  if (summary.pendingCount > 0)
                    FilledButton(
                      onPressed: () async {
                        await ref
                            .read(adminWalletServiceProvider)
                            .settleAll(summary.workerId);
                        onRefresh();
                        ref.invalidate(workerEntriesProvider(summary.workerId));
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          textStyle: const TextStyle(fontSize: 13)),
                      child: const Text('Collect All'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('No transactions',
                          style: TextStyle(color: Colors.grey)));
                  }
                  // Group by date
                  final byDate = <String, List<WalletEntry>>{};
                  for (final e in list) {
                    final key = DateFormat('yyyy-MM-dd').format(e.createdAt);
                    byDate.putIfAbsent(key, () => []).add(e);
                  }
                  final dates = byDate.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  return ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final dateKey in dates) ...[
                        _DateHeader(dateKey: dateKey),
                        const SizedBox(height: 4),
                        ...byDate[dateKey]!.map((e) => _EntryCard(
                              entry: e,
                              onSettle: () async {
                                await ref
                                    .read(adminWalletServiceProvider)
                                    .settleEntry(e.id);
                                onRefresh();
                                ref.invalidate(
                                    workerEntriesProvider(summary.workerId));
                              },
                            )),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date header ───────────────────────────────────────────────────────────────

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

// ── Entry card ────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final WalletEntry entry;
  final VoidCallback onSettle;
  const _EntryCard({required this.entry, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');
    final isPending = entry.isPending;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isPending ? Colors.white : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
            color: isPending
                ? Colors.orange.withOpacity(0.3)
                : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.payments_outlined,
                  color: Colors.green[700], size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.customerName ?? 'Customer',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(_svc(entry.serviceType),
                      style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  if (entry.scheduledAt != null)
                    Text(fmt.format(entry.scheduledAt!),
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 10)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.amount} EGP',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isPending ? Colors.orange[700] : Colors.grey)),
                const SizedBox(height: 4),
                if (isPending)
                  GestureDetector(
                    onTap: onSettle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Collect',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  Text('Done ✓',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _svc(String? t) => switch (t) {
        'fullService' => 'Full Service',
        'interiorOnly' => 'Interior Only',
        _ => 'Exterior Only',
      };
}

// ── Day detail bottom sheet ───────────────────────────────────────────────────

class _DayDetailSheet extends ConsumerWidget {
  final DateTime date;
  const _DayDetailSheet({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(companyDayEntriesProvider(date));
    final label = DateUtils.isSameDay(date, DateTime.now())
        ? 'Today'
        : DateFormat('EEEE, MMM d').format(date);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                entries.whenOrNull(
                  data: (list) {
                    final total = list.fold(0, (s, e) => s + e.amount);
                    return Text('$total EGP',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 15));
                  },
                ) ?? const SizedBox(),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                        child: Text('No transactions',
                            style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _CompanyEntryCard(entry: list[i]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyEntryCard extends StatelessWidget {
  final CompanyDayEntry entry;
  const _CompanyEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isInstapay = entry.source == 'instapay';
    final isCash = entry.source == 'cash_collected';
    final isCard = entry.source == 'credit_card';

    final color = isInstapay
        ? Colors.blue
        : isCard
            ? Colors.purple
            : Colors.orange;
    final icon = isInstapay
        ? Icons.mobile_friendly
        : isCard
            ? Icons.credit_card
            : Icons.payments_outlined;
    final sourceLabel = isInstapay
        ? 'InstaPay'
        : isCard
            ? 'Credit Card'
            : 'Cash Collected';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.customerName ?? 'Customer',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(sourceLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ),
                    if (entry.serviceType != null) ...[
                      const SizedBox(width: 6),
                      Text(_svc(entry.serviceType),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ]),
                  if (entry.workerName != null)
                    Text('via ${entry.workerName}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
            Text('${entry.amount} EGP',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color)),
          ],
        ),
      ),
    );
  }

  String _svc(String? t) => switch (t) {
        'fullService' => 'Full Service',
        'interiorOnly' => 'Interior Only',
        _ => 'Exterior Only',
      };
}
