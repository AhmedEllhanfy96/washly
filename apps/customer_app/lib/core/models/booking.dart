import 'car.dart';

enum ServiceType { exteriorOnly, interiorOnly, fullService }

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String get label => switch (this) {
        pending => 'Pending',
        confirmed => 'Confirmed',
        inProgress => 'In Progress',
        completed => 'Completed',
        cancelled => 'Cancelled',
      };

  static BookingStatus fromString(String value) =>
      BookingStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => BookingStatus.pending,
      );
}

class BookingLocation {
  final String address;
  final double latitude;
  final double longitude;

  const BookingLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory BookingLocation.fromJson(Map<String, dynamic> json) => BookingLocation(
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class Booking {
  final String id;
  final String userId;
  final Car car;
  final ServiceType serviceType;
  final BookingLocation location;
  final DateTime scheduledAt;
  final String timeSlot;
  final BookingStatus status;
  final String? assignedTo;
  final String? notes;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.car,
    required this.serviceType,
    required this.location,
    required this.scheduledAt,
    required this.timeSlot,
    required this.status,
    this.assignedTo,
    this.notes,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? '',
        car: Car.fromMap((json['car'] as Map<String, dynamic>?) ?? {}),
        serviceType: _parseServiceType(json['serviceType'] as String?),
        location: BookingLocation(
          address: json['address'] as String? ?? '',
          latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        ),
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        timeSlot: json['timeSlot'] as String? ?? '',
        status: BookingStatus.fromString(json['status'] as String? ?? 'pending'),
        assignedTo: json['assignedTo'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static ServiceType _parseServiceType(String? v) => switch (v) {
    'fullService' => ServiceType.fullService,
    'interiorOnly' => ServiceType.interiorOnly,
    _ => ServiceType.exteriorOnly,
  };

  Map<String, dynamic> toJson() => {
        'car': car.toMap(),
        'serviceType': serviceType.name,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'scheduledAt': scheduledAt.toIso8601String(),
        'timeSlot': timeSlot,
      };

  Booking copyWith({BookingStatus? status, String? assignedTo}) => Booking(
        id: id,
        userId: userId,
        car: car,
        serviceType: serviceType,
        location: location,
        scheduledAt: scheduledAt,
        timeSlot: timeSlot,
        status: status ?? this.status,
        assignedTo: assignedTo ?? this.assignedTo,
        notes: notes,
        createdAt: createdAt,
      );
}
