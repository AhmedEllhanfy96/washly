import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/bookings_provider.dart';
import '../../shared/widgets/language_toggle_button.dart';
import '../../shared/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final pending = ref.watch(pendingBookingsProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: l10n.customers,
            onPressed: () => context.go('/dashboard/customers'),
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: l10n.workers,
            onPressed: () => context.go('/dashboard/team'),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l10n.allBookings,
            onPressed: () => context.go('/dashboard/bookings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(adminAuthProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            stats.when(
              data: (s) => Row(
                children: [
                  _StatCard(
                      label: l10n.pendingLabel,
                      value: '${s['pending']}',
                      color: Colors.orange,
                      icon: Icons.hourglass_empty),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: l10n.confirmedLabel,
                      value: '${s['confirmed']}',
                      color: Colors.blue,
                      icon: Icons.check_circle_outline),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: l10n.todayLabel,
                      value: '${s['today']}',
                      color: Colors.green,
                      icon: Icons.today),
                ],
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.pendingApprovals,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/dashboard/bookings'),
                  child: Text(l10n.viewAll),
                ),
              ],
            ),
            const SizedBox(height: 8),

            pending.when(
              data: (list) {
                if (list.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(l10n.noPendingBookings,
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    ),
                  );
                }
                return Column(
                  children: list
                      .take(10)
                      .map((b) => _PendingBookingCard(booking: b))
                      .toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingBookingCard extends ConsumerWidget {
  final AdminBooking booking;

  const _PendingBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('EEE, MMM d • h:mm a');
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            context.go('/dashboard/bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 6),
              _Info(Icons.directions_car, booking.carSummary),
              _Info(Icons.cleaning_services,
                  l10n.serviceTypeName(booking.serviceType)),
              _Info(Icons.location_on, booking.address),
              _Info(Icons.calendar_today,
                  fmt.format(booking.scheduledAt)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Info(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: Colors.grey[700], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
}
