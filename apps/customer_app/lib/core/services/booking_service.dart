import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/time_slot.dart';
import '../services/ws_service.dart';
import 'api_client.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(wsServiceProvider));
});

class BookingService {
  final Dio _dio = createDio();
  final WsService _ws;

  BookingService(this._ws);

  Future<String> createBooking({
    required Booking booking,
    required String customerName,
    required String customerPhone,
  }) async {
    final res = await _dio.post('/bookings', data: {
      ...booking.toJson(),
      'customerName': customerName,
      'customerPhone': customerPhone,
    });
    return (res.data as Map<String, dynamic>)['id'] as String;
  }

  Stream<List<Booking>> watchUserBookings(String userId) {
    final controller = StreamController<List<Booking>>();

    Future<void> fetch() async {
      if (controller.isClosed) return;
      try {
        final res = await _dio.get('/bookings');
        final all = (res.data as List)
            .map((j) => Booking.fromJson(j as Map<String, dynamic>))
            .toList();
        if (!controller.isClosed) controller.add(all);
      } catch (_) {}
    }

    fetch();
    // Periodic fallback every 30s
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
    // Instant update on WS event
    final wsSub = _ws.events.listen((_) => fetch());

    controller.onCancel = () {
      timer.cancel();
      wsSub.cancel();
    };

    return controller.stream;
  }

  Future<List<TimeSlot>> getAvailableSlots(DateTime date) async {
    try {
      final res = await _dio.get('/slots/${_dateKey(date)}');
      return (res.data as List)
          .map((j) => TimeSlot.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return TimeSlot.defaultSlots();
    }
  }

  Future<void> cancelBooking(String id) =>
      _dio.patch('/bookings/$id/status', data: {'status': 'cancelled'});

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
