import 'manga.dart';
import 'chapter.dart';

abstract class MangaSource {
  String get id;
  String get name;
  String get baseUrl;
  String get readerBaseUrl;

  Map<String, String>? get headers => null;

  Future<List<Manga>> getPopularManga({int page = 1});
  Future<List<Chapter>> getChapters(String mangaId);
  Future<List<String>> getPageUrls(String chapterId);
}
