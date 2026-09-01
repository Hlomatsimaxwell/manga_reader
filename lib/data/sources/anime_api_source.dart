import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/manga_source.dart';
import '../models/manga.dart';
import '../models/chapter.dart';

class AnimeApiSource implements MangaSource {
  @override
  String get id => 'anime_api';

  @override
  String get name => 'Anime-API';

  @override
  String get baseUrl => 'https://anime-api.vercel.app/api';

  @override
  String get readerBaseUrl => 'https://anime-api.vercel.app/api';

  @override
  Map<String, String>? get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  Future<List<Manga>> getPopularManga({int page = 1}) async {
    debugPrint('API: Fetching popular manga...');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manga'),
        headers: headers,
      ).timeout(const Duration(seconds: 10)); // STOP waiting after 10 seconds

      debugPrint('API: Popular manga response code: ${response.statusCode}');

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      debugPrint('API: Successfully parsed ${data.length} manga');

      return data.map((item) {
        return Manga(
          id: item['id']?.toString() ?? '',
          sourceId: this.id,
          title: item['title'] ?? 'Unknown Title',
          coverUrl: item['image'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('API ERROR (Popular): $e');
      return [];
    }
  }

  @override
  Future<List<Chapter>> getChapters(String mangaId) async {
    debugPrint('API: Fetching chapters for $mangaId...');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manga/$mangaId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint('API: Chapter response code: ${response.statusCode}');

      if (response.statusCode != 200) return [];

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> chaptersData = data['chapters'] ?? [];
      debugPrint('API: Found ${chaptersData.length} chapters');

      return chaptersData.map((chapter) {
        return Chapter(
          id: chapter['id']?.toString() ?? '',
          title: chapter['title'] ?? '',
          chapterNumber: chapter['chapterNumber']?.toString() ?? '',
          releaseDate: '',
          url: chapter['url'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('API ERROR (Chapters): $e');
      return [];
    }
  }

  @override
  Future<List<String>> getPageUrls(String chapterId) async {
    debugPrint('API: Fetching pages for $chapterId...');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chapter/$chapterId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint('API: Page response code: ${response.statusCode}');

      if (response.statusCode != 200) return [];

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> pages = data['pages'] ?? [];
      debugPrint('API: Found ${pages.length} pages');

      return pages.map((url) => url.toString()).toList();
    } catch (e) {
      debugPrint('API ERROR (Pages): $e');
      return [];
    }
  }
}
