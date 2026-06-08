class Slide {
  final String id;
  final String imageUrl;
  final String title;
  final String caption;
  final int sortOrder;

  const Slide({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.caption,
    required this.sortOrder,
  });

  factory Slide.fromJson(Map<String, dynamic> json) => Slide(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String? ?? '',
        title: json['title'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
