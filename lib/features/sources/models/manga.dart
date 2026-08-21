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

class Chapter {
  final String id;
  final String title;
  final String chapterNumber;
  final String? releaseDate;
  final String url;

  Chapter({
    required this.id,
    required this.title,
    required this.chapterNumber,
    this.releaseDate,
    required this.url,
  });
}