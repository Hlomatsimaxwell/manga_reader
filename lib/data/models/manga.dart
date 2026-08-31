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
}
