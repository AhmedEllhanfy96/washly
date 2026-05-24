class CustomerAccount {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int bookingCount;
  final DateTime createdAt;

  const CustomerAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.bookingCount,
    required this.createdAt,
  });

  factory CustomerAccount.fromJson(Map<String, dynamic> json) =>
      CustomerAccount(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
