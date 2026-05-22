class Car {
  final String make;
  final String model;
  final String color;
  final String plateNumber;
  final String? year;

  const Car({
    required this.make,
    required this.model,
    required this.color,
    required this.plateNumber,
    this.year,
  });

  factory Car.fromMap(Map<String, dynamic> map) => Car(
        make: map['make'] as String,
        model: map['model'] as String,
        color: map['color'] as String,
        plateNumber: map['plateNumber'] as String,
        year: map['year'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'make': make,
        'model': model,
        'color': color,
        'plateNumber': plateNumber,
        'year': year,
      };

  String get displayName => '$year $make $model'.trim();
}
