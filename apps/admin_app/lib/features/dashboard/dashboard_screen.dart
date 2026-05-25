import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';
import '../../core/models/team_member.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/bookings_provider.dart';
import '../../shared/widgets/language_toggle_button.dart';
import '../../shared/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allBookingsProvider);
    final teamAsync = ref.watch(teamMembersProvider);
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
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: l10n.scheduleManagement,
            onPressed: () => context.go('/dashboard/schedule'),
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
          final confirmed =
              bookings.where((b) => b.status == BookingStatus.confirmed).length;
          final inProgress =
              bookings.where((b) => b.status == BookingStatus.inProgress).toList();
          final completedToday = bookings
              .where((b) =>
                  b.status == BookingStatus.completed && isToday(b.scheduledAt))
              .toList();
          final todaySchedule = bookings
              .where((b) =>
                  isToday(b.scheduledAt) &&
                  (b.status == BookingStatus.confirmed ||
                      b.status == BookingStatus.inProgress))
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          // Oldest pending waiting time
          String? oldestWait;
          if (pending.isNotEmpty) {
            final diff = now.difference(pending.first.createdAt);
            if (diff.inMinutes < 60) {
              oldestWait = '${diff.inMinutes}m';
            } else if (diff.inHours < 24) {
              oldestWait = '${diff.inHours}h';
            } else {
              oldestWait = '${diff.inDays}d';
            }
          }

          // Revenue for completed today
          int revenue = 0;
          for (final b in completedToday) {
            revenue += switch (b.serviceType) {
              ServiceType.exteriorOnly => AppConfig.priceExteriorOnly,
              ServiceType.interiorOnly => AppConfig.priceInteriorOnly,
              ServiceType.fullService => AppConfig.priceFullService,
            };
          }

          final workers = teamAsync.valueOrNull ?? <TeamMember>[];
          String workerName(String? id) {
            if (id == null) return l10n.unassigned;
            try {
              return workers.firstWhere((w) => w.id == id).name;
            } catch (_) {
              return l10n.unassigned;
            }
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allBookingsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Stats 2×2 grid ───────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      label: l10n.pendingLabel,
                      value: '${pending.length}',
                      color: Colors.orange,
                      icon: Icons.hourglass_empty,
                      subtitle: oldestWait != null
                          ? '${l10n.waitingLabel} $oldestWait'
                          : null,
                      onTap: () => context.go('/dashboard/bookings'),
                    ),
                    _StatCard(
                      label: l10n.confirmedLabel,
                      value: '$confirmed',
                      color: Colors.blue,
                      icon: Icons.check_circle_outline,
                      subtitle: '${todaySchedule.where((b) => b.status == BookingStatus.confirmed).length} ${l10n.todayLabel}',
                      onTap: () => context.go('/dashboard/bookings'),
                    ),
                    _StatCard(
                      label: l10n.inProgressLabel,
                      value: '${inProgress.length}',
                      color: Colors.deepPurple,
                      icon: Icons.local_car_wash,
                      onTap: () => context.go('/dashboard/bookings'),
                    ),
                    _StatCard(
                      label: l10n.completedTodayLabel,
                      value: '${completedToday.length}',
                      color: Colors.green,
                      icon: Icons.check_circle,
                      subtitle: revenue > 0 ? '$revenue EGP' : null,
                      onTap: () => context.go('/dashboard/bookings'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Today's Schedule ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.todaySchedule,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(DateFormat('EEE, d MMM').format(now),
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                if (todaySchedule.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          Icon(Icons.event_available,
                              color: Colors.green[300], size: 36),
                          const SizedBox(height: 8),
                          Text(l10n.noScheduleToday,
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                else
                  ...todaySchedule.map((b) => _TodayBookingCard(
                        booking: b,
                        workerName: workerName(b.assignedTo),
                      )),

                const SizedBox(height: 24),

                // ── Pending Approvals ────────────────────────────────────
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
                if (pending.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(l10n.noPendingBookings,
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    ),
                  )
                else
                  ...pending
                      .take(AppConfig.dashboardPendingLimit)
                      .map((b) => _PendingBookingCard(booking: b, now: now)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: color,
                            height: 1.1)),
                    Text(label,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: TextStyle(
                              color: color.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Today's schedule card ────────────────────────────────────────────────────

class _TodayBookingCard extends StatelessWidget {
  final AdminBooking booking;
  final String workerName;

  const _TodayBookingCard({required this.booking, required this.workerName});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isInProgress = booking.status == BookingStatus.inProgress;
    final timeColor =
        isInProgress ? Colors.deepPurple : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isInProgress
            ? const BorderSide(color: Colors.deepPurple, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => context.go('/dashboard/bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: timeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      booking.timeSlot.split('–').first.trim(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: timeColor),
                    ),
                    if (isInProgress)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.local_car_wash,
                            size: 14, color: Colors.deepPurple),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(booking.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        StatusBadge(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _Row(Icons.directions_car, booking.carSummary),
                    _Row(Icons.cleaning_services,
                        l10n.serviceTypeName(booking.serviceType)),
                    _Row(
                      booking.assignedTo != null
                          ? Icons.person
                          : Icons.person_outline,
                      workerName,
                      color: booking.assignedTo != null
                          ? null
                          : Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pending booking card ─────────────────────────────────────────────────────

class _PendingBookingCard extends StatelessWidget {
  final AdminBooking booking;
  final DateTime now;

  const _PendingBookingCard({required this.booking, required this.now});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d • h:mm a');
    final l10n = context.l10n;
    final diff = now.difference(booking.createdAt);
    final waitStr = diff.inMinutes < 60
        ? '${diff.inMinutes}m'
        : diff.inHours < 24
            ? '${diff.inHours}h'
            : '${diff.inDays}d';
    final waitColor =
        diff.inHours >= AppConfig.pendingAlertHours ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/dashboard/bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(booking.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: waitColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${l10n.waitingLabel} $waitStr',
                      style: TextStyle(
                          color: waitColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _Row(Icons.directions_car, booking.carSummary),
              _Row(Icons.cleaning_services,
                  l10n.serviceTypeName(booking.serviceType)),
              _Row(Icons.location_on, booking.address),
              _Row(Icons.calendar_today, fmt.format(booking.scheduledAt)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared row widget ────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _Row(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    color: color ?? Colors.grey[700], fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
