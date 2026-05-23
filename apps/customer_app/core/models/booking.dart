import 'package:cloud_firestore/cloud_firestore.dart';
import 'car.dart';

enum ServiceType { exteriorOnly, fullService }

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

  factory BookingLocation.fromMap(Map<String, dynamic> map) => BookingLocation(
        address: map['address'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
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

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] as String,
      car: Car.fromMap(data['car'] as Map<String, dynamic>),
      serviceType: data['serviceType'] == 'fullService'
          ? ServiceType.fullService
          : ServiceType.exteriorOnly,
      location:
          BookingLocation.fromMap(data['location'] as Map<String, dynamic>),
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] as String,
      status: BookingStatus.fromString(data['status'] as String),
      assignedTo: data['assignedTo'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'car': car.toMap(),
        'serviceType': serviceType.name,
        'location': location.toMap(),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'timeSlot': timeSlot,
        'status': status.name,
        'assignedTo': assignedTo,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
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
