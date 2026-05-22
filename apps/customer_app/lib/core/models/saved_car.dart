class SavedCar {
  final String id;
  final String make;
  final String model;
  final String color;
  final String plateNumber;
  final String? year;

  const SavedCar({
    required this.id,
    required this.make,
    required this.model,
    required this.color,
    required this.plateNumber,
    this.year,
  });

  factory SavedCar.fromJson(Map<String, dynamic> json) => SavedCar(
        id: json['id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        color: json['color'] as String,
        plateNumber: json['plateNumber'] as String,
        year: json['year'] as String?,
      );

  String get displayName {
    final parts = [if (year != null && year!.isNotEmpty) year, make, model];
    return parts.join(' ');
  }
}
