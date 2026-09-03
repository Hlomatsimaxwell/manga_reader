import 'package:dio/dio.dart';
import '../models/manga_source.dart';
import '../models/manga.dart';
import '../models/chapter.dart';

class MangaDexSource implements MangaSource {
  @override
  String get id => 'mangadex';

  @override
  String get name => 'MangaDex';

  @override
  String get baseUrl => 'https://api.mangadex.org';

  @override
  String get readerBaseUrl => 'https://cdn.mangadex.org';

  @override
  Map<String, String>? get headers => {
        'User-Agent': 'MangaReader/1.0',
        'Accept': 'application/json',
      };

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.mangadex.org',
    headers: {
      'User-Agent': 'MangaReader/1.0',
    },
  ));

  @override
  Future<List<Manga>> getPopularManga({int page = 1}) async {
    try {
      // MangaDex uses 'offset' instead of 'page'
      int offset = (page - 1) * 20;
      final response = await _dio.get('/manga', queryParameters: {
        'limit': 20,
        'offset': offset,
        'order': {'followedCount': 'desc'},
        'includes[]': 'cover_art',
      });

      final List<dynamic> data = response.data['data'];
      return data.map((item) {
        final mangaId = item['id'];
        // Extract cover filename from the cover_art relationship
        String coverFileName = '';
        final List relationships = item['relationships'] ?? [];
        for (var rel in relationships) {
          if (rel['type'] == 'cover_art') {
            coverFileName = rel['attributes']?['fileName'] ?? '';
            break;
          }
        }
        return Manga(
          id: mangaId,
          sourceId: this.id,
          title: _extractTitle(item['attributes']['title'] ?? {}),
          coverUrl: coverFileName.isNotEmpty
              ? 'https://uploads.mangadex.org/covers/$mangaId/$coverFileName.256.jpg'
              : '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Chapter>> getChapters(String mangaId) async {
    try {
      final response = await _dio.get('/manga/$mangaId/feed', queryParameters: {
        'order': {'chapter': 'desc'},
        'translatedLanguage[]': 'en',
        'limit': 100,
      });

      final List<dynamic> data = response.data['data'];
      return data.map((item) {
        return Chapter(
          id: item['id'],
          title: item['attributes']['chapter'] ?? 'Chapter',
          chapterNumber: item['attributes']['chapter'] ?? '0',
          releaseDate: '',
          url: '', // Not used by the reader
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<String>> getPageUrls(String chapterId) async {    try {
      // 1. Get the "at-home" server URL for the chapter
      final response = await _dio.get('/at-home/server/$chapterId');
      final String baseUrl = response.data['baseUrl'];
      final String hash = response.data['chapter']['hash'];
      final List<dynamic> filenames = response.data['chapter']['data'];

      // 2. Construct the full URLs
      // Format: baseUrl + "/data/" + hash + "/" + filename
      return filenames.map((file) => '$baseUrl/data/$hash/$file').toList();
    } catch (e) {
      return [];
    }
  }

  // Pick the best available title (prefer English, fall back to any language)
  String _extractTitle(dynamic titleMap) {
    if (titleMap is! Map) return 'Unknown Title';
    final t = titleMap;
    if (t['en'] is String && (t['en'] as String).isNotEmpty) {
      return t['en'] as String;
    }
    for (final v in t.values) {
      if (v is String && v.isNotEmpty) return v;
    }
    return 'Unknown Title';
  }
}
