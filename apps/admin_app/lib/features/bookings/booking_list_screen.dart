import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';
import '../../core/providers/bookings_provider.dart';
import '../../shared/widgets/status_badge.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  BookingStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final allBookings = ref.watch(allBookingsProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allBookings),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _FilterChip(
                    label: l10n.all,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null)),
                ...BookingStatus.values.map((s) => _FilterChip(
                      label: l10n.statusLabel(s),
                      selected: _filter == s,
                      onTap: () => setState(() => _filter = s),
                    )),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/dashboard/bookings/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.manualBooking),
      ),
      body: allBookings.when(
        data: (bookings) {
          final filtered = _filter == null
              ? bookings
              : bookings.where((b) => b.status == _filter).toList();

          if (filtered.isEmpty) {
            return Center(
                child: Text(l10n.noBookings,
                    style: const TextStyle(color: Colors.grey)));
          }

          // Group by scheduled date
          final byDay = <String, List<AdminBooking>>{};
          for (final b in filtered) {
            final key = DateFormat('yyyy-MM-dd').format(b.scheduledAt);
            byDay.putIfAbsent(key, () => []).add(b);
          }

          // Sort days: today first, then future ascending, then past descending
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final days = byDay.keys.toList()
            ..sort((a, b) {
              if (a == today) return -1;
              if (b == today) return 1;
              final aFuture = a.compareTo(today) > 0;
              final bFuture = b.compareTo(today) > 0;
              if (aFuture && !bFuture) return -1;
              if (!aFuture && bFuture) return 1;
              return aFuture ? a.compareTo(b) : b.compareTo(a);
            });

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allBookingsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              children: [
                for (final day in days) ...[
                  _DayHeader(dateKey: day, count: byDay[day]!.length),
                  const SizedBox(height: 4),
                  ...byDay[day]!.map((b) => _BookingTile(booking: b)),
                  const SizedBox(height: 8),
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

// ── Day header ────────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  final String dateKey; // yyyy-MM-dd
  final int count;
  const _DayHeader({required this.dateKey, required this.count});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final tomorrow = DateFormat('yyyy-MM-dd')
        .format(now.add(const Duration(days: 1)));

    final String label;
    final Color color;
    if (dateKey == today) {
      label = 'Today';
      color = Theme.of(context).colorScheme.primary;
    } else if (dateKey == tomorrow) {
      label = 'Tomorrow';
      color = Colors.orange[700]!;
    } else if (dateKey.compareTo(today) > 0) {
      label = DateFormat('EEEE, MMM d').format(date);
      color = Colors.orange[400]!;
    } else {
      label = DateFormat('EEEE, MMM d').format(date);
      color = Colors.grey[500]!;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

// ── Booking tile ──────────────────────────────────────────────────────────────

class _BookingTile extends StatelessWidget {
  final AdminBooking booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('h:mm a');
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/dashboard/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Text(
                  booking.customerName.isNotEmpty
                      ? booking.customerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.access_time_outlined,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(booking.timeSlot.isNotEmpty
                          ? booking.timeSlot
                          : timeFmt.format(booking.scheduledAt),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      Icon(Icons.directions_car_outlined,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(booking.carSummary,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
              // Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: booking.status),
                  if (booking.source != 'app') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        booking.source == 'whatsapp'
                            ? 'WhatsApp'
                            : booking.source,
                        style:
                            TextStyle(fontSize: 10, color: Colors.green[700]),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
