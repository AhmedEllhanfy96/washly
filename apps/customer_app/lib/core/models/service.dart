class WashService {
  final String id;
  final String key;
  final String name;
  final String description;
  final int price;
  final bool isActive;
  final int sortOrder;
  final String category;
  final String imageUrl;
  final List<String> features;
  final String badge;

  const WashService({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    required this.sortOrder,
    required this.category,
    required this.imageUrl,
    required this.features,
    required this.badge,
  });

  factory WashService.fromJson(Map<String, dynamic> json) => WashService(
        id: json['id'] as String,
        key: json['key'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        category: json['category'] as String? ?? 'wash',
        imageUrl: json['imageUrl'] as String? ?? '',
        features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
        badge: json['badge'] as String? ?? '',
      );
}
