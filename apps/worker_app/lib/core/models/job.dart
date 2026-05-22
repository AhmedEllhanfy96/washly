enum JobStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String get label => switch (this) {
        pending => 'Pending',
        confirmed => 'Confirmed',
        inProgress => 'In Progress',
        completed => 'Completed',
        cancelled => 'Cancelled',
      };

  static JobStatus fromString(String v) =>
      JobStatus.values.firstWhere((e) => e.name == v, orElse: () => JobStatus.pending);
}

class Job {
  final String id;
  final String customerName;
  final String customerPhone;
  final Map<String, dynamic> car;
  final String serviceType;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;
  final String timeSlot;
  final JobStatus status;

  const Job({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.car,
    required this.serviceType,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    required this.timeSlot,
    required this.status,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as String,
        customerName: json['customerName'] as String? ?? '',
        customerPhone: json['customerPhone'] as String? ?? '',
        car: (json['car'] as Map<String, dynamic>?) ?? {},
        serviceType: json['serviceType'] as String? ?? 'exteriorOnly',
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        timeSlot: json['timeSlot'] as String? ?? '',
        status: JobStatus.fromString(json['status'] as String? ?? 'pending'),
      );

  String get carSummary {
    final make = car['make'] ?? '';
    final model = car['model'] ?? '';
    final color = car['color'] ?? '';
    return '$color $make $model'.trim();
  }

  String get serviceName =>
      serviceType == 'fullService' ? 'Full Interior + Exterior — 250 EGP' : 'Exterior Only — 195 EGP';

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }
}
