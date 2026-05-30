import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
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
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
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
                emptyIcon: Icons.calendar_today_outlined,
                ref: ref,
                showCancel: true,
              ),
              _BookingList(
                bookings: list
                    .where((b) => b.status == BookingStatus.completed)
                    .toList(),
                emptyMessage: l10n.noCompletedBookings,
                emptyIcon: Icons.check_circle_outline,
                ref: ref,
              ),
              _BookingList(
                bookings: list
                    .where((b) => b.status == BookingStatus.cancelled)
                    .toList(),
                emptyMessage: l10n.noCancelledBookings,
                emptyIcon: Icons.cancel_outlined,
                ref: ref,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        // FAB to book a new wash
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/home/book'),
          icon: const Icon(Icons.water_drop),
          label: Text(l10n.bookAWash),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyMessage;
  final IconData emptyIcon;
  final WidgetRef ref;
  final bool showCancel;

  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.ref,
    this.showCancel = false,
  });

  Future<void> _cancel(BuildContext context, Booking booking) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cancelBookingTitle),
        content: Text(l10n.cancelBookingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.yesCancel),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(bookingServiceProvider).cancelBooking(booking.id);
      ref.invalidate(userBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.bookingCancelledSuccess),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.couldNotCancelBooking),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final b = bookings[i];
        final canCancel = showCancel &&
            (b.status == BookingStatus.pending ||
                b.status == BookingStatus.confirmed);
        return BookingStatusCard(
          booking: b,
          onCancel: canCancel ? () => _cancel(context, b) : null,
        );
      },
    );
  }
}
