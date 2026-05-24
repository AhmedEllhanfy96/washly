import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final scheduleServiceProvider =
    Provider<ScheduleService>((ref) => ScheduleService());

class ScheduleConfig {
  final int windowDuration; // hours: 1 or 2
  final int capacityPerWindow; // workers / max bookings per slot
  final String dayStart; // "HH:MM"
  final String dayEnd; // "HH:MM"
  final bool isClosed;

  const ScheduleConfig({
    required this.windowDuration,
    required this.capacityPerWindow,
    required this.dayStart,
    required this.dayEnd,
    required this.isClosed,
  });

  factory ScheduleConfig.defaults() => const ScheduleConfig(
        windowDuration: 2,
        capacityPerWindow: 3,
        dayStart: '08:00',
        dayEnd: '18:00',
        isClosed: false,
      );

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) => ScheduleConfig(
        windowDuration: (json['windowDuration'] as num?)?.toInt() ?? 2,
        capacityPerWindow: (json['capacityPerWindow'] as num?)?.toInt() ?? 3,
        dayStart: json['dayStart'] as String? ?? '08:00',
        dayEnd: json['dayEnd'] as String? ?? '18:00',
        isClosed: json['isClosed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'windowDuration': windowDuration,
        'capacityPerWindow': capacityPerWindow,
        'dayStart': dayStart,
        'dayEnd': dayEnd,
        'isClosed': isClosed,
      };

  ScheduleConfig copyWith({
    int? windowDuration,
    int? capacityPerWindow,
    String? dayStart,
    String? dayEnd,
    bool? isClosed,
  }) =>
      ScheduleConfig(
        windowDuration: windowDuration ?? this.windowDuration,
        capacityPerWindow: capacityPerWindow ?? this.capacityPerWindow,
        dayStart: dayStart ?? this.dayStart,
        dayEnd: dayEnd ?? this.dayEnd,
        isClosed: isClosed ?? this.isClosed,
      );

  /// Generate time slot labels from config (for preview).
  List<String> get slotLabels {
    if (isClosed) return [];
    final parts = (String t) => t.split(':').map(int.parse).toList();
    final s = parts(dayStart);
    final e = parts(dayEnd);
    int t = s[0] * 60 + s[1];
    final end = e[0] * 60 + e[1];
    final pad = (int n) => n.toString().padLeft(2, '0');
    final slots = <String>[];
    while (t + windowDuration * 60 <= end) {
      final et = t + windowDuration * 60;
      slots.add('${pad(t ~/ 60)}:${pad(t % 60)} – ${pad(et ~/ 60)}:${pad(et % 60)}');
      t = et;
    }
    return slots;
  }
}

class ScheduleService {
  final Dio _dio = createDio();

  Future<ScheduleConfig> getConfig(String date) async {
    final res = await _dio.get<Map<String, dynamic>>('/slots/config/$date');
    return ScheduleConfig.fromJson(res.data!);
  }

  Future<void> setConfig(String date, ScheduleConfig config) async {
    await _dio.put('/slots/config/$date', data: config.toJson());
  }

  Future<void> resetConfig(String date) async {
    await _dio.delete('/slots/config/$date');
  }
}
