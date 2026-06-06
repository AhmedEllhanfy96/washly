import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/car.dart';
import '../models/service.dart';
import '../models/time_slot.dart';
import '../services/booking_service.dart';
import 'auth_provider.dart';

final userBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.valueOrNull?.id;
  if (userId == null) return Stream.value([]);
  return ref.watch(bookingServiceProvider).watchUserBookings(userId);
});

final availableSlotsProvider =
    FutureProvider.family<List<TimeSlot>, DateTime>((ref, date) {
  return ref.watch(bookingServiceProvider).getAvailableSlots(date);
});

// ── Booking flow state ────────────────────────────────────────────────────────

class BookingFlowState {
  final Car? car;
  final WashService? service;
  final BookingLocation? location;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final PaymentMethod paymentMethod;
  final String? promoCode;
  final int discountPercent;

  const BookingFlowState({
    this.car,
    this.service,
    this.location,
    this.selectedDate,
    this.selectedTimeSlot,
    this.paymentMethod = PaymentMethod.cash,
    this.promoCode,
    this.discountPercent = 0,
  });

  bool get isComplete =>
      car != null &&
      service != null &&
      location != null &&
      selectedDate != null &&
      selectedTimeSlot != null;

  int get finalPrice => discountPercent > 0
      ? (service!.price * (1 - discountPercent / 100)).round()
      : (service?.price ?? 0);

  BookingFlowState copyWith({
    Car? car,
    WashService? service,
    BookingLocation? location,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    PaymentMethod? paymentMethod,
    String? promoCode,
    int? discountPercent,
    bool clearPromo = false,
  }) =>
      BookingFlowState(
        car: car ?? this.car,
        service: service ?? this.service,
        location: location ?? this.location,
        selectedDate: selectedDate ?? this.selectedDate,
        selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
        discountPercent: clearPromo ? 0 : (discountPercent ?? this.discountPercent),
      );
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  BookingFlowNotifier() : super(const BookingFlowState());

  void setCar(Car car) => state = state.copyWith(car: car);
  void setService(WashService service) => state = state.copyWith(service: service);
  void setLocation(BookingLocation location) => state = state.copyWith(location: location);
  void setSchedule(DateTime date, String slot) =>
      state = state.copyWith(selectedDate: date, selectedTimeSlot: slot);
  void setPaymentMethod(PaymentMethod method) => state = state.copyWith(paymentMethod: method);
  void setPromo(String code, int discountPercent) =>
      state = state.copyWith(promoCode: code, discountPercent: discountPercent);
  void clearPromo() => state = state.copyWith(clearPromo: true);
  void reset() => state = const BookingFlowState();
}

final bookingFlowProvider =
    StateNotifierProvider<BookingFlowNotifier, BookingFlowState>(
        (ref) => BookingFlowNotifier());
