import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/booking.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/services/booking_service.dart';
import '../../shared/widgets/booking_status_card.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(userBookingsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: bookings.when(
          data: (list) => TabBarView(
            children: [
              _BookingList(
                bookings: list
                    .where((b) => [
                          BookingStatus.pending,
                          BookingStatus.confirmed,
                          BookingStatus.inProgress,
                        ].contains(b.status))
                    .toList(),
                emptyMessage: 'No active bookings',
                ref: ref,
              ),
              _BookingList(
                bookings: list
                    .where((b) => b.status == BookingStatus.completed)
                    .toList(),
                emptyMessage: 'No completed bookings yet',
                ref: ref,
              ),
              _BookingList(
                bookings: list
                    .where((b) => b.status == BookingStatus.cancelled)
                    .toList(),
                emptyMessage: 'No cancelled bookings',
                ref: ref,
              ),
            ],
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyMessage;
  final WidgetRef ref;

  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    required this.ref,
  });

  Future<void> _cancel(BuildContext context, Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Yes, cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(bookingServiceProvider).cancelBooking(booking.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final b = bookings[i];
        return BookingStatusCard(
          booking: b,
          onTap: b.status == BookingStatus.pending
              ? () => _cancel(context, b)
              : null,
        );
      },
    );
  }
}
