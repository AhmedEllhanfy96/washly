class Worker {
  final String id;
  final String name;
  final String phone;
  final String? email;

  const Worker({required this.id, required this.name, required this.phone, this.email});

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
      );
}
