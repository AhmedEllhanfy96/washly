class WorkerLocation {
  final String workerId;
  final String name;
  final double lat;
  final double lng;
  final DateTime updatedAt;

  const WorkerLocation({
    required this.workerId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory WorkerLocation.fromJson(Map<String, dynamic> json) => WorkerLocation(
        workerId: json['workerId'] as String,
        name: json['name'] as String? ?? 'Worker',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Duration get lastSeenAgo => DateTime.now().difference(updatedAt);

  String get lastSeenLabel {
    final mins = lastSeenAgo.inMinutes;
    if (mins < 1) return 'Just now';
    if (mins < 60) return '${mins}m ago';
    return '${lastSeenAgo.inHours}h ago';
  }

  bool get isOnline => lastSeenAgo.inMinutes < 3;
}
