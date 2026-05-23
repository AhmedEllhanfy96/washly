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

class AdminBooking {
  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final Map<String, dynamic> car;
  final ServiceType serviceType;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;
  final String timeSlot;
  final BookingStatus status;
  final String? assignedTo;
  final String? notes;
  final String source;
  final DateTime createdAt;
  final String address;

  const AdminBooking({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.car,
    required this.serviceType,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.scheduledAt,
    required this.timeSlot,
    required this.status,
    this.assignedTo,
    this.notes,
    this.source = 'app',
    required this.createdAt,
  });

  factory AdminBooking.fromJson(Map<String, dynamic> json) => AdminBooking(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? 'Unknown',
        customerPhone: json['customerPhone'] as String? ?? '',
        car: (json['car'] as Map<String, dynamic>?) ?? {},
        serviceType: _parseServiceType(json['serviceType'] as String?),
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        address: json['address'] as String? ?? '',
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        timeSlot: json['timeSlot'] as String? ?? '',
        status: BookingStatus.fromString(json['status'] as String? ?? 'pending'),
        assignedTo: json['assignedTo'] as String?,
        notes: json['notes'] as String?,
        source: json['source'] as String? ?? 'app',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static ServiceType _parseServiceType(String? v) => switch (v) {
    'fullService' => ServiceType.fullService,
    'interiorOnly' => ServiceType.interiorOnly,
    _ => ServiceType.exteriorOnly,
  };

  // Keep location map interface for booking_detail_screen compatibility
  Map<String, dynamic> get location => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  String get carSummary {
    final make = car['make'] ?? '';
    final model = car['model'] ?? '';
    final color = car['color'] ?? '';
    return '$color $make $model'.trim();
  }
}
