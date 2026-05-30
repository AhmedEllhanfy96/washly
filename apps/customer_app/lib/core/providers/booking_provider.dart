import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/car.dart';
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
  final ServiceType? serviceType;
  final BookingLocation? location;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final PaymentMethod paymentMethod;

  const BookingFlowState({
    this.car,
    this.serviceType,
    this.location,
    this.selectedDate,
    this.selectedTimeSlot,
    this.paymentMethod = PaymentMethod.cash,
  });

  bool get isComplete =>
      car != null &&
      serviceType != null &&
      location != null &&
      selectedDate != null &&
      selectedTimeSlot != null;

  BookingFlowState copyWith({
    Car? car,
    ServiceType? serviceType,
    BookingLocation? location,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    PaymentMethod? paymentMethod,
  }) =>
      BookingFlowState(
        car: car ?? this.car,
        serviceType: serviceType ?? this.serviceType,
        location: location ?? this.location,
        selectedDate: selectedDate ?? this.selectedDate,
        selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
        paymentMethod: paymentMethod ?? this.paymentMethod,
      );
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  BookingFlowNotifier() : super(const BookingFlowState());

  void setCar(Car car) => state = state.copyWith(car: car);
  void setServiceType(ServiceType type) => state = state.copyWith(serviceType: type);
  void setLocation(BookingLocation location) => state = state.copyWith(location: location);
  void setSchedule(DateTime date, String slot) =>
      state = state.copyWith(selectedDate: date, selectedTimeSlot: slot);
  void setPaymentMethod(PaymentMethod method) => state = state.copyWith(paymentMethod: method);
  void reset() => state = const BookingFlowState();
}

final bookingFlowProvider =
    StateNotifierProvider<BookingFlowNotifier, BookingFlowState>(
        (ref) => BookingFlowNotifier());

final submitBookingProvider = FutureProvider.autoDispose<String?>((ref) async {
  final flow = ref.watch(bookingFlowProvider);
  final user = ref.watch(authProvider).valueOrNull;
  if (!flow.isComplete || user == null) return null;

  final booking = Booking(
    id: '',
    userId: user.id,
    car: flow.car!,
    serviceType: flow.serviceType!,
    location: flow.location!,
    scheduledAt: flow.selectedDate!,
    timeSlot: flow.selectedTimeSlot!,
    status: BookingStatus.pending,
    createdAt: DateTime.now(),
  );
  return ref.watch(bookingServiceProvider).createBooking(
        booking: booking,
        customerName: user.name,
        customerPhone: user.phone ?? '',
      );
});
