import 'package:cloud_firestore/cloud_firestore.dart';

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

class AdminBooking {
  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final Map<String, dynamic> car;
  final ServiceType serviceType;
  final Map<String, dynamic> location;
  final DateTime scheduledAt;
  final String timeSlot;
  final BookingStatus status;
  final String? assignedTo;
  final String? notes;
  final DateTime createdAt;

  const AdminBooking({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
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

  factory AdminBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminBooking(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Unknown',
      customerPhone: data['customerPhone'] as String? ?? '',
      car: (data['car'] as Map<String, dynamic>?) ?? {},
      serviceType: data['serviceType'] == 'fullService'
          ? ServiceType.fullService
          : ServiceType.exteriorOnly,
      location: (data['location'] as Map<String, dynamic>?) ?? {},
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot'] as String? ?? '',
      status: BookingStatus.fromString(data['status'] as String? ?? 'pending'),
      assignedTo: data['assignedTo'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get carSummary {
    final make = car['make'] ?? '';
    final model = car['model'] ?? '';
    final color = car['color'] ?? '';
    return '$color $make $model'.trim();
  }

  String get address => location['address'] as String? ?? '';
}
