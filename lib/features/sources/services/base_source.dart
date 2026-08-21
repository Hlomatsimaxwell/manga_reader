import 'package:manga_reader/features/sources/models/manga.dart';
import 'package:manga_reader/features/sources/models/chapter.dart' as app;

abstract class BaseSource {
  String get name;
  Future<List<Manga>> getPopularManga({int page = 1});
  Future<List<app.Chapter>> getChapters(String mangaId);
  Future<List<String>> getPageList(app.Chapter chapter);
  Future<List<String>> getPageUrls(String chapterId);
}