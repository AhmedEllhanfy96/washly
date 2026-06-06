import 'car.dart';

enum PaymentMethod {
  cash,
  instapay,
  credit_card;

  String get label => switch (this) {
        cash => 'Pay on Arrival',
        instapay => 'InstaPay',
        credit_card => 'Credit Card',
      };

  static PaymentMethod fromString(String v) =>
      PaymentMethod.values.firstWhere((e) => e.name == v, orElse: () => PaymentMethod.cash);
}

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
  final String serviceType;
  final String serviceName;
  final BookingLocation location;
  final DateTime scheduledAt;
  final String timeSlot;
  final BookingStatus status;
  final String? assignedTo;
  final String? notes;
  final PaymentMethod paymentMethod;
  final String paymentStatus;
  final int price;
  final int originalPrice;
  final int discountPercent;
  final String? promoCode;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.car,
    required this.serviceType,
    this.serviceName = '',
    required this.location,
    required this.scheduledAt,
    required this.timeSlot,
    required this.status,
    this.assignedTo,
    this.notes,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = 'pending',
    this.price = 0,
    this.originalPrice = 0,
    this.discountPercent = 0,
    this.promoCode,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? '',
        car: Car.fromMap((json['car'] as Map<String, dynamic>?) ?? {}),
        serviceType: json['serviceType'] as String? ?? 'exterior_only',
        serviceName: json['serviceName'] as String? ?? '',
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
        paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String? ?? 'cash'),
        paymentStatus: json['paymentStatus'] as String? ?? 'pending',
        price: (json['price'] as num?)?.toInt() ?? 0,
        originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 0,
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        promoCode: json['promoCode'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'car': car.toMap(),
        'serviceType': serviceType,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'scheduledAt': scheduledAt.toIso8601String(),
        'timeSlot': timeSlot,
        'paymentMethod': paymentMethod.name,
        if (promoCode != null) 'promoCode': promoCode,
      };

  Booking copyWith({BookingStatus? status, String? assignedTo}) => Booking(
        id: id,
        userId: userId,
        car: car,
        serviceType: serviceType,
        serviceName: serviceName,
        location: location,
        scheduledAt: scheduledAt,
        timeSlot: timeSlot,
        status: status ?? this.status,
        assignedTo: assignedTo ?? this.assignedTo,
        notes: notes,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        price: price,
        originalPrice: originalPrice,
        discountPercent: discountPercent,
        promoCode: promoCode,
        createdAt: createdAt,
      );
}
