import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/bookings_provider.dart';
import '../../shared/widgets/language_toggle_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allBookingsProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(adminAuthProvider.notifier).signOut(),
          ),
        ],
      ),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bookings) {
          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day);
          bool isToday(DateTime d) =>
              DateTime(d.year, d.month, d.day) == todayDate;

          final pending = bookings
              .where((b) => b.status == BookingStatus.pending)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          final confirmed = bookings
              .where((b) => b.status == BookingStatus.confirmed)
              .length;
          final inProgress = bookings
              .where((b) => b.status == BookingStatus.inProgress)
              .length;
          final doneToday = bookings
              .where((b) =>
                  b.status == BookingStatus.completed && isToday(b.scheduledAt))
              .length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allBookingsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: [
                // ── Date ─────────────────────────────────────────────────
                Text(
                  DateFormat('EEEE, d MMM').format(now),
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),

                // ── Stats row (compact) ───────────────────────────────────
                Row(
                  children: [
                    _Stat(pending.length, l10n.pendingLabel, Colors.orange,
                        urgent: pending.isNotEmpty),
                    _Stat(confirmed, l10n.confirmedLabel, Colors.blue),
                    _Stat(inProgress, l10n.inProgressLabel, Colors.deepPurple),
                    _Stat(doneToday, l10n.completedTodayLabel, Colors.green),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Action tiles (3-col) ──────────────────────────────────
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.15,
                  children: [
                    _Tile(
                      icon: Icons.list_alt,
                      label: l10n.allBookings,
                      color: Colors.blue,
                      badge: pending.isNotEmpty ? pending.length : null,
                      onTap: () => context.go('/dashboard/bookings'),
                    ),
                    _Tile(
                      icon: Icons.group,
                      label: l10n.workers,
                      color: Colors.teal,
                      onTap: () => context.go('/dashboard/team'),
                    ),
                    _Tile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Wallets',
                      color: Colors.orange[700]!,
                      onTap: () => context.go('/dashboard/wallet'),
                    ),
                    _Tile(
                      icon: Icons.settings,
                      label: 'Settings',
                      color: Colors.grey[600]!,
                      onTap: () => context.go('/dashboard/pricing'),
                    ),
                    _Tile(
                      icon: Icons.people_alt_outlined,
                      label: l10n.customers,
                      color: Colors.indigo,
                      onTap: () => context.go('/dashboard/customers'),
                    ),
                    _Tile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Schedule',
                      color: Colors.deepPurple,
                      onTap: () => context.go('/dashboard/schedule'),
                    ),
                    _Tile(
                      icon: Icons.cleaning_services_outlined,
                      label: 'Services',
                      color: Colors.teal[700]!,
                      onTap: () => context.go('/dashboard/services'),
                    ),
                    _Tile(
                      icon: Icons.local_offer_outlined,
                      label: 'Promos',
                      color: Colors.pink[700]!,
                      onTap: () => context.go('/dashboard/promos'),
                    ),
                    _Tile(
                      icon: Icons.map_outlined,
                      label: 'Workers Map',
                      color: Colors.blue[800]!,
                      onTap: () => context.go('/dashboard/workers-map'),
                    ),
                    _Tile(
                      icon: Icons.slideshow_outlined,
                      label: 'Slides',
                      color: Colors.deepOrange,
                      onTap: () => context.go('/dashboard/slides'),
                    ),
                  ],
                ),

                // ── Pending ───────────────────────────────────────────────
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Text(l10n.pendingApprovals,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('${pending.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      TextButton(
                        onPressed: () => context.go('/dashboard/bookings'),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text(l10n.viewAll,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...pending
                      .take(4)
                      .map((b) => _PendingRow(booking: b, now: now)),
                  if (pending.length > 4)
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/dashboard/bookings'),
                        child: Text(
                            '${pending.length - 4} more…',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 12)),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Compact stat ──────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final int n;
  final String label;
  final Color color;
  final bool urgent;

  const _Stat(this.n, this.label, this.color, {this.urgent = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$n',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: urgent && n > 0 ? Colors.orange : color),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _Tile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.18)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Pending row ───────────────────────────────────────────────────────────────

class _PendingRow extends StatelessWidget {
  final AdminBooking booking;
  final DateTime now;

  const _PendingRow({required this.booking, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final diff = now.difference(booking.createdAt);
    final wait = diff.inMinutes < 60
        ? '${diff.inMinutes}m'
        : diff.inHours < 24
            ? '${diff.inHours}h'
            : '${diff.inDays}d';
    final isOld = diff.inHours >= 1;
    final needsPayment = booking.paymentMethod == 'instapay' &&
        booking.paymentStatus != 'confirmed';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: isOld
                ? Colors.orange.withOpacity(0.35)
                : Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => context.go('/dashboard/bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      '${l10n.serviceTypeName(booking.serviceType)}  ·  ${booking.timeSlot}',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (needsPayment)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.warning_amber,
                      color: Colors.orange, size: 14),
                ),
              Text(wait,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOld ? Colors.orange[700] : Colors.grey[500])),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
