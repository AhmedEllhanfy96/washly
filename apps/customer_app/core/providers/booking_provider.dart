import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/car.dart';
import '../models/time_slot.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';

// ── Active bookings stream ────────────────────────────────────────────────────

final userBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(bookingServiceProvider).watchUserBookings(user.uid);
});

// ── Available time slots ──────────────────────────────────────────────────────

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

  const BookingFlowState({
    this.car,
    this.serviceType,
    this.location,
    this.selectedDate,
    this.selectedTimeSlot,
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
  }) =>
      BookingFlowState(
        car: car ?? this.car,
        serviceType: serviceType ?? this.serviceType,
        location: location ?? this.location,
        selectedDate: selectedDate ?? this.selectedDate,
        selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
      );
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  BookingFlowNotifier() : super(const BookingFlowState());

  void setCar(Car car) => state = state.copyWith(car: car);
  void setServiceType(ServiceType type) =>
      state = state.copyWith(serviceType: type);
  void setLocation(BookingLocation location) =>
      state = state.copyWith(location: location);
  void setSchedule(DateTime date, String slot) =>
      state = state.copyWith(selectedDate: date, selectedTimeSlot: slot);
  void reset() => state = const BookingFlowState();
}

final bookingFlowProvider =
    StateNotifierProvider<BookingFlowNotifier, BookingFlowState>(
  (ref) => BookingFlowNotifier(),
);

// ── Submit booking ────────────────────────────────────────────────────────────

final submitBookingProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final flow = ref.watch(bookingFlowProvider);
  final user = ref.watch(authServiceProvider).currentUser;
  if (!flow.isComplete || user == null) return null;

  final booking = Booking(
    id: '',
    userId: user.uid,
    car: flow.car!,
    serviceType: flow.serviceType!,
    location: flow.location!,
    scheduledAt: flow.selectedDate!,
    timeSlot: flow.selectedTimeSlot!,
    status: BookingStatus.pending,
    createdAt: DateTime.now(),
  );
  return ref.watch(bookingServiceProvider).createBooking(booking);
});
