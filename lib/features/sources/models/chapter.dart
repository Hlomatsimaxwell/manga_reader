class Chapter {
  final String id;
  final String title;
  final String chapterNumber;
  final String releaseDate;
  final String url;

  Chapter({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.releaseDate,
    required this.url,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      chapterNumber: json['chapterNumber'] ?? '',
      releaseDate: json['releaseDate'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'chapterNumber': chapterNumber,
      'releaseDate': releaseDate,
      'url': url,
    };
  }
}