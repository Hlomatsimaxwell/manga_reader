import '../models/manga_source.dart';
import '../models/manga.dart';
import '../models/chapter.dart';

class MockSource implements MangaSource {
  @override
  String get id => 'mock';

  @override
  String get name => 'Mock Source';

  @override
  String get baseUrl => 'https://mock.com';

  @override
  String get readerBaseUrl => 'https://mock-reader.com';

  @override
  Map<String, String>? get headers => null;

  @override
  Future<List<Manga>> getPopularManga({int page = 1}) async {
    return [
      Manga(id: '1', sourceId: id, title: 'Mock Manga 1', coverUrl: 'https://picsum.photos/seed/mock1/300/450'),
      Manga(id: '2', sourceId: id, title: 'Mock Manga 2', coverUrl: 'https://picsum.photos/seed/mock2/300/450'),
    ];
  }

  @override
  Future<List<Chapter>> getChapters(String mangaId) async {
    return [
      Chapter(id: 'c1', title: 'Chapter 1', chapterNumber: '1', releaseDate: '', url: ''),
      Chapter(id: 'c2', title: 'Chapter 2', chapterNumber: '2', releaseDate: '', url: ''),
    ];
  }

  @override
  Future<List<String>> getPageUrls(String chapterId) async {
    return List.generate(
      10,
      (index) =>
          'https://picsum.photos/seed/mock_ch_$chapterId${index + 1}/800/1200',
    );
  }
}
