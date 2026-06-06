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
  final String serviceType;
  final String serviceName;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;
  final String timeSlot;
  final BookingStatus status;
  final String? assignedTo;
  final String? notes;
  final String source;
  final String paymentMethod;
  final String paymentStatus;
  final int price;
  final int originalPrice;
  final int discountPercent;
  final String? promoCode;
  final DateTime createdAt;
  final String address;

  const AdminBooking({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.car,
    required this.serviceType,
    this.serviceName = '',
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.scheduledAt,
    required this.timeSlot,
    required this.status,
    this.assignedTo,
    this.notes,
    this.source = 'app',
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.price = 0,
    this.originalPrice = 0,
    this.discountPercent = 0,
    this.promoCode,
    required this.createdAt,
  });

  factory AdminBooking.fromJson(Map<String, dynamic> json) => AdminBooking(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? 'Unknown',
        customerPhone: json['customerPhone'] as String? ?? '',
        car: (json['car'] as Map<String, dynamic>?) ?? {},
        serviceType: json['serviceType'] as String? ?? 'exterior_only',
        serviceName: json['serviceName'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        address: json['address'] as String? ?? '',
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        timeSlot: json['timeSlot'] as String? ?? '',
        status: BookingStatus.fromString(json['status'] as String? ?? 'pending'),
        assignedTo: json['assignedTo'] as String?,
        notes: json['notes'] as String?,
        source: json['source'] as String? ?? 'app',
        paymentMethod: json['paymentMethod'] as String? ?? 'cash',
        paymentStatus: json['paymentStatus'] as String? ?? 'pending',
        price: (json['price'] as num?)?.toInt() ?? 0,
        originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 0,
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        promoCode: json['promoCode'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

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

  String get displayServiceName =>
      serviceName.isNotEmpty ? serviceName : serviceType;
}
