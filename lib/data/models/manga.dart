class Manga {
  final String id;
  final String title;
  final String coverUrl;
  final String? description;
  final String sourceId;

  Manga({
    required this.id,
    required this.title,
    required this.coverUrl,
    this.description,
    required this.sourceId,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      description: json['description'],
      sourceId: json['sourceId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'description': description,
      'sourceId': sourceId,
    };
  }
}
