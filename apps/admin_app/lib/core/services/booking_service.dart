import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/team_member.dart';
import '../services/ws_service.dart';
import 'api_client.dart';

final adminBookingServiceProvider = Provider<AdminBookingService>((ref) {
  return AdminBookingService(ref.read(wsServiceProvider));
});

class AdminBookingService {
  final Dio _dio = createDio();
  final WsService _ws;

  AdminBookingService(this._ws);

  Stream<List<AdminBooking>> watchAllBookings() => _watchBookings();

  Stream<List<AdminBooking>> watchBookingsByStatus(BookingStatus status) =>
      watchAllBookings().map((l) => l.where((b) => b.status == status).toList());

  Stream<List<AdminBooking>> _watchBookings() {
    final controller = StreamController<List<AdminBooking>>();

    Future<void> fetch() async {
      if (controller.isClosed) return;
      try {
        final res = await _dio.get('/bookings');
        final list = (res.data as List)
            .map((j) => AdminBooking.fromJson(j as Map<String, dynamic>))
            .toList();
        if (!controller.isClosed) controller.add(list);
      } catch (_) {}
    }

    fetch();
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
    final wsSub = _ws.events.listen((_) => fetch());

    controller.onCancel = () {
      timer.cancel();
      wsSub.cancel();
    };

    return controller.stream;
  }

  Future<void> updateStatus(String bookingId, BookingStatus status) =>
      _dio.patch('/bookings/$bookingId/status', data: {'status': status.name});

  Future<void> assignTeamMember(String bookingId, String memberId) =>
      _dio.patch('/bookings/$bookingId/assign', data: {'memberId': memberId});

  Future<void> addNote(String bookingId, String note) =>
      _dio.patch('/bookings/$bookingId/status', data: {'notes': note});

  // Team members
  Stream<List<TeamMember>> watchTeamMembers() {
    final controller = StreamController<List<TeamMember>>();

    Future<void> fetch() async {
      if (controller.isClosed) return;
      try {
        final res = await _dio.get('/team');
        final list = (res.data as List)
            .map((j) => TeamMember.fromJson(j as Map<String, dynamic>))
            .toList();
        if (!controller.isClosed) controller.add(list);
      } catch (_) {}
    }

    fetch();
    final timer = Timer.periodic(const Duration(seconds: 60), (_) => fetch());
    controller.onCancel = () => timer.cancel();

    return controller.stream;
  }

  Future<void> addTeamMember(TeamMember member) =>
      _dio.post('/team', data: member.toJson());

  Future<void> updateAvailability(String memberId, bool available) =>
      _dio.patch('/team/$memberId', data: {'isAvailable': available});

  Future<void> deleteTeamMember(String memberId) =>
      _dio.delete('/team/$memberId');

  Future<Map<String, int>> getStats() async {
    final all = await _dio.get('/bookings').then(
        (r) => (r.data as List).map((j) => AdminBooking.fromJson(j as Map<String, dynamic>)).toList());
    final now = DateTime.now();
    return {
      'pending': all.where((b) => b.status == BookingStatus.pending).length,
      'confirmed': all.where((b) => b.status == BookingStatus.confirmed).length,
      'today': all.where((b) {
        final d = b.scheduledAt;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).length,
    };
  }
}
