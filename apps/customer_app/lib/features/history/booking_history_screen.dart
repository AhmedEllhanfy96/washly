import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/services/booking_service.dart';
import '../../shared/widgets/booking_status_card.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(userBookingsProvider);
    final l10n = context.l10n;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myBookings),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabActive),
              Tab(text: l10n.tabCompleted),
              Tab(text: l10n.tabCancelled),
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
                emptyMessage: l10n.noActiveBookings,
                ref: ref,
              ),
              _BookingList(
                bookings: list
                    .where((b) => b.status == BookingStatus.completed)
                    .toList(),
                emptyMessage: l10n.noCompletedBookings,
                ref: ref,
              ),
              _BookingList(
                bookings: list
                    .where((b) => b.status == BookingStatus.cancelled)
                    .toList(),
                emptyMessage: l10n.noCancelledBookings,
                ref: ref,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
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
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.cancelBookingTitle),
        content: Text(l10n.cancelBookingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yesCancel,
                style: const TextStyle(color: Colors.red)),
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
