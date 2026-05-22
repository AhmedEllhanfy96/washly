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
    final end = json['endTime'] as String? ?? addTwoHours(start);
    return TimeSlot(
      startTime: start,
      endTime: end,
      available: json['available'] as bool? ?? true,
      maxBookings: (json['maxBookings'] as num?)?.toInt() ?? 3,
      currentBookings: (json['currentBookings'] as num?)?.toInt() ?? 0,
    );
  }

  static String addTwoHours(String t) {
    final parts = t.split(':');
    final h = (int.parse(parts[0]) + 2) % 24;
    return '${h.toString().padLeft(2, '0')}:${parts[1]}';
  }

  static List<TimeSlot> defaultSlots() => [
        ('08:00', '10:00'),
        ('10:00', '12:00'),
        ('12:00', '14:00'),
        ('14:00', '16:00'),
        ('16:00', '18:00'),
      ]
          .map((p) => TimeSlot(
                startTime: p.$1,
                endTime: p.$2,
                available: true,
                maxBookings: 3,
                currentBookings: 0,
              ))
          .toList();
}
