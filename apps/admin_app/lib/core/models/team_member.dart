class TeamMember {
  final String id;
  final String name;
  final String phone;
  final bool isAvailable;

  const TeamMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.isAvailable,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'isAvailable': isAvailable,
      };
}
