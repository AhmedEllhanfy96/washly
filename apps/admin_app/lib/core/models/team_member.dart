import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isAvailable;
  final int completedJobs;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isAvailable,
    required this.completedJobs,
  });

  factory TeamMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamMember(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? true,
      completedJobs: (data['completedJobs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'isAvailable': isAvailable,
        'completedJobs': completedJobs,
      };
}
