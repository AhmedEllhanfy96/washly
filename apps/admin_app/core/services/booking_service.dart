import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/team_member.dart';

final adminBookingServiceProvider =
    Provider<AdminBookingService>((ref) => AdminBookingService());

class AdminBookingService {
  final _db = FirebaseFirestore.instance;

  Stream<List<AdminBooking>> watchBookingsByStatus(BookingStatus status) => _db
      .collection('bookings')
      .where('status', isEqualTo: status.name)
      .orderBy('scheduledAt')
      .snapshots()
      .map((s) => s.docs.map(AdminBooking.fromFirestore).toList());

  Stream<List<AdminBooking>> watchAllBookings() => _db
      .collection('bookings')
      .orderBy('scheduledAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AdminBooking.fromFirestore).toList());

  Future<void> updateStatus(String bookingId, BookingStatus status) =>
      _db.collection('bookings').doc(bookingId).update({
        'status': status.name,
      });

  Future<void> assignTeamMember(String bookingId, String memberId) =>
      _db.collection('bookings').doc(bookingId).update({
        'assignedTo': memberId,
        'status': BookingStatus.confirmed.name,
      });

  Future<void> addNote(String bookingId, String note) =>
      _db.collection('bookings').doc(bookingId).update({'notes': note});

  // Team members
  Stream<List<TeamMember>> watchTeamMembers() => _db
      .collection('team_members')
      .snapshots()
      .map((s) => s.docs.map(TeamMember.fromFirestore).toList());

  Future<void> addTeamMember(TeamMember member) =>
      _db.collection('team_members').add(member.toFirestore());

  Future<void> updateAvailability(String memberId, bool available) =>
      _db
          .collection('team_members')
          .doc(memberId)
          .update({'isAvailable': available});

  Future<void> deleteTeamMember(String memberId) =>
      _db.collection('team_members').doc(memberId).delete();

  // Dashboard stats
  Future<Map<String, int>> getStats() async {
    final pending = await _db
        .collection('bookings')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    final confirmed = await _db
        .collection('bookings')
        .where('status', isEqualTo: 'confirmed')
        .count()
        .get();
    final today = await _db
        .collection('bookings')
        .where('scheduledAt',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(_startOfDay(DateTime.now())))
        .where('scheduledAt',
            isLessThan:
                Timestamp.fromDate(_startOfDay(DateTime.now().add(const Duration(days: 1)))))
        .count()
        .get();
    return {
      'pending': pending.count ?? 0,
      'confirmed': confirmed.count ?? 0,
      'today': today.count ?? 0,
    };
  }

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
