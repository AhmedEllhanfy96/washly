import '../config/app_config.dart';

class TimeSlot {
  final String startTime;
  final String endTime;
  final bool available;
  final int maxBookings;
  final int currentBookings;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.available,
    required this.maxBookings,
    required this.currentBookings,
  });

  String get time => startTime;
  bool get isBookable => available && currentBookings < maxBookings;

  String get displayLabel => '${_fmt(startTime)} – ${_fmt(endTime)}';

  String _fmt(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final suffix = h < 12 ? 'AM' : 'PM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:${parts[1]} $suffix';
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    final start = (json['startTime'] ?? json['time']) as String;
    final end = json['endTime'] as String? ?? _addHours(start, AppConfig.slotDurationHours);
    return TimeSlot(
      startTime: start,
      endTime: end,
      available: json['available'] as bool? ?? true,
      maxBookings: (json['maxBookings'] as num?)?.toInt() ?? AppConfig.maxBookingsPerSlot,
      currentBookings: (json['currentBookings'] as num?)?.toInt() ?? 0,
    );
  }

  static String addTwoHours(String t) => _addHours(t, AppConfig.slotDurationHours);

  static String _addHours(String t, int hours) {
    final parts = t.split(':');
    final h = (int.parse(parts[0]) + hours) % 24;
    return '${h.toString().padLeft(2, '0')}:${parts[1]}';
  }

  static List<TimeSlot> defaultSlots() {
    final slots = <(String, String)>[];
    var hour = int.parse(AppConfig.dayStart.split(':')[0]);
    final endHour = int.parse(AppConfig.dayEnd.split(':')[0]);
    while (hour < endHour) {
      final next = hour + AppConfig.slotDurationHours;
      slots.add((
        '${hour.toString().padLeft(2, '0')}:00',
        '${next.toString().padLeft(2, '0')}:00',
      ));
      hour = next;
    }
    return slots
        .map((p) => TimeSlot(
              startTime: p.$1,
              endTime: p.$2,
              available: true,
              maxBookings: AppConfig.maxBookingsPerSlot,
              currentBookings: 0,
            ))
        .toList();
  }
}
