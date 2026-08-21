import 'services/base_source.dart';
import 'models/manga.dart';
import 'models/chapter.dart' as app_chapter;

class MockMangaSource implements BaseSource {
  @override
  String get name => 'Demo Manga';

  @override
  Future<List<Manga>> getPopularManga({int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    return List.generate(
      12,
      (index) => Manga(
        id: 'manga_$index',
        sourceId: 'mock_source',
        title: 'Sample Manga Title #${index + 1}',
        coverUrl: 'https://picsum.photos/seed/$index/300/400',
      ),
    );
  }

  @override
  Future<List<app_chapter.Chapter>> getChapters(String mangaId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return List.generate(
      10,
      (index) => app_chapter.Chapter(
        id: 'chap_$index',
        title: 'Chapter ${index + 1}',
        chapterNumber: '${index + 1}',
        releaseDate: '2026-01-01',
        url: 'https://example.com/chapter_$index',
      ),
    );
  }

  @override
  Future<List<String>> getPageList(app_chapter.Chapter chapter) async {
    return getPageUrls(chapter.id);
  }

  @override
  Future<List<String>> getPageUrls(String chapterId) async {
    return List.generate(
      5,
      (index) => 'https://picsum.photos/seed/page_$index/400/600',
    );
  }
}