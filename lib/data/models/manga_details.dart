class MangaDetails {
  final String id;
  final String title;
  final String coverUrl;
  final String sourceId;
  final String description;
  final String author;
  final String status; // e.g. 'ongoing', 'completed'
  final String year;
  final List<String> tags;
  final int followers;
  final int totalChapters;

  const MangaDetails({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.sourceId,
    this.description = '',
    this.author = '',
    this.status = '',
    this.year = '',
    this.tags = const [],
    this.followers = 0,
    this.totalChapters = 0,
  });
}
