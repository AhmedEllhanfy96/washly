import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/team_member.dart';
import '../services/booking_service.dart';

final allBookingsProvider = StreamProvider<List<AdminBooking>>((ref) {
  return ref.watch(adminBookingServiceProvider).watchAllBookings();
});

final pendingBookingsProvider = StreamProvider<List<AdminBooking>>((ref) {
  return ref
      .watch(adminBookingServiceProvider)
      .watchBookingsByStatus(BookingStatus.pending);
});

final confirmedBookingsProvider = StreamProvider<List<AdminBooking>>((ref) {
  return ref
      .watch(adminBookingServiceProvider)
      .watchBookingsByStatus(BookingStatus.confirmed);
});

final teamMembersProvider = StreamProvider<List<TeamMember>>((ref) {
  return ref.watch(adminBookingServiceProvider).watchTeamMembers();
});

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(adminBookingServiceProvider).getStats();
});
