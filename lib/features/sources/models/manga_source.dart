import 'manga.dart';

abstract class MangaSource {
  String get id;
  String get name;
  String get baseUrl;

  // Fetch catalog/popular manga
  Future<List<Manga>> getPopularManga(int page);

  // Fetch chapter list for a manga
  Future<List<Chapter>> getChapterList(String mangaUrl);

  // Fetch image URLs for a chapter
  Future<List<String>> getPageList(Chapter chapter);
}