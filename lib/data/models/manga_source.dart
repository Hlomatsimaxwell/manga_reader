import 'manga.dart';
import 'chapter.dart';
import 'manga_details.dart';

abstract class MangaSource {
  String get id;
  String get name;
  String get baseUrl;
  String get readerBaseUrl;

  Map<String, String>? get headers => null;

  Future<List<Manga>> getPopularManga({int page = 1});
  Future<MangaDetails?> getMangaDetails(String mangaId);
  Future<List<Chapter>> getChapters(String mangaId);
  Future<List<String>> getPageUrls(String chapterId);

  // The source's authoritative chapter count (may exceed the number of
  // chapter *entries* currently loaded). Returns 0 when unknown.
  Future<int> getTotalChapters(String mangaId) async {
    return 0;
  }
}
