import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/time_slot.dart';

final bookingServiceProvider =
    Provider<BookingService>((ref) => BookingService());

class BookingService {
  final _db = FirebaseFirestore.instance;

  Future<String> createBooking(Booking booking) async {
    final ref = await _db.collection('bookings').add(booking.toFirestore());
    // Increment slot counter
    await _incrementSlotCounter(
      date: _dateKey(booking.scheduledAt),
      time: booking.timeSlot,
    );
    return ref.id;
  }

  Stream<List<Booking>> watchUserBookings(String userId) => _db
      .collection('bookings')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Booking.fromFirestore).toList());

  Future<Booking?> getBooking(String id) async {
    final doc = await _db.collection('bookings').doc(id).get();
    if (!doc.exists) return null;
    return Booking.fromFirestore(doc);
  }

  Future<void> cancelBooking(String bookingId) => _db
      .collection('bookings')
      .doc(bookingId)
      .update({'status': BookingStatus.cancelled.name});

  Future<List<TimeSlot>> getAvailableSlots(DateTime date) async {
    final key = _dateKey(date);
    final doc = await _db.collection('time_slots').doc(key).get();
    if (!doc.exists) return DaySlots.defaultSlots();
    return DaySlots.fromFirestore(doc).slots;
  }

  Future<void> _incrementSlotCounter({
    required String date,
    required String time,
  }) async {
    final ref = _db.collection('time_slots').doc(date);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final slots = (snap.data()!['slots'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      final idx = slots.indexWhere((s) => s['time'] == time);
      if (idx != -1) slots[idx]['currentBookings'] = (slots[idx]['currentBookings'] as int) + 1;
      tx.update(ref, {'slots': slots});
    });
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
