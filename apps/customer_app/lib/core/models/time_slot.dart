import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final String time;       // e.g. "09:00"
  final bool available;
  final int maxBookings;
  final int currentBookings;

  const TimeSlot({
    required this.time,
    required this.available,
    required this.maxBookings,
    required this.currentBookings,
  });

  bool get isBookable => available && currentBookings < maxBookings;

  factory TimeSlot.fromMap(Map<String, dynamic> map) => TimeSlot(
        time: map['time'] as String,
        available: map['available'] as bool? ?? true,
        maxBookings: (map['maxBookings'] as num?)?.toInt() ?? 3,
        currentBookings: (map['currentBookings'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'time': time,
        'available': available,
        'maxBookings': maxBookings,
        'currentBookings': currentBookings,
      };
}

class DaySlots {
  final String date;  // yyyy-MM-dd
  final List<TimeSlot> slots;

  const DaySlots({required this.date, required this.slots});

  factory DaySlots.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawSlots = data['slots'] as List<dynamic>? ?? [];
    return DaySlots(
      date: doc.id,
      slots: rawSlots
          .map((s) => TimeSlot.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<TimeSlot> defaultSlots() => [
        '08:00', '09:00', '10:00', '11:00',
        '13:00', '14:00', '15:00', '16:00', '17:00',
      ]
          .map((t) => TimeSlot(
                time: t,
                available: true,
                maxBookings: 3,
                currentBookings: 0,
              ))
          .toList();
}
