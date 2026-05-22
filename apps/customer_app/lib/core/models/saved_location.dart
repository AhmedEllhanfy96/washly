class SavedLocation {
  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;

  const SavedLocation({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        id: json['id'] as String,
        label: json['label'] as String,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}
