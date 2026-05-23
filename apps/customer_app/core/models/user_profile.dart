import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'customer' | 'admin'
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      role: data['role'] as String? ?? 'customer',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
