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
          preferredSize: const Size.fromHeight(56),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _BookingTile(booking: filtered[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

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

class _BookingTile extends StatelessWidget {
  final AdminBooking booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, h:mm a');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.go('/dashboard/bookings/${booking.id}'),
        leading: CircleAvatar(
          child: Text(
            booking.customerName.isNotEmpty
                ? booking.customerName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(booking.customerName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.carSummary),
            Text(fmt.format(booking.scheduledAt)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: booking.status),
            if (booking.source != 'app') ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.source == 'whatsapp' ? 'WhatsApp' : booking.source,
                  style: TextStyle(fontSize: 10, color: Colors.green[800]),
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
