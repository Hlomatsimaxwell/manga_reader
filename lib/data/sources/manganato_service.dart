import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/manga_source.dart';
import '../models/manga.dart';
import '../models/chapter.dart';

class ManganatoService implements MangaSource {
  @override
  String get id => 'manganato';

  @override
  String get name => 'Manganato';

  @override
  String get baseUrl => 'https://manganato.com';

  @override
  String get readerBaseUrl => 'https://chapmanganato.to'; // <--- Defined here

  @override
  Map<String, String> get headers => {
        'Referer': 'https://manganato.com/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      };

  @override
  Future<List<Manga>> getPopularManga({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/genre-all/$page'),
        headers: headers,
      );
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final elements = document.querySelectorAll('.content-genres-item');

      return elements.map((element) {
        final titleEl = element.querySelector('.genres-item-name');
        final imgEl = element.querySelector('img');
        final url = titleEl?.attributes['href'] ?? '';
        final id = url.split('/').last;

        return Manga(
          id: id,
          sourceId: this.id,
          title: titleEl?.text.trim() ?? '',
          coverUrl: imgEl?.attributes['src'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching popular manga: $e');
      return [];
    }
  }

  @override
  Future<List<Chapter>> getChapters(String mangaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manga-$mangaId'),
        headers: headers,
      );
      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      final elements = document.querySelectorAll('.row-content-chapter .a-h');

      return elements.map((element) {
        final url = element.attributes['href'] ?? '';
        final id = url.split('/').last;

        return Chapter(
          id: id,
          title: element.text.trim(),
          chapterNumber: element.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          releaseDate: '',
          url: url,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching chapters: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getPageUrls(String chapterId) async {
    try {
      // Logic: If it's already a URL, use it. Otherwise, use the readerBaseUrl.
      final String targetUrl = chapterId.startsWith('http') 
          ? chapterId 
          : '$readerBaseUrl/$chapterId';

      final response = await http.get(
        Uri.parse(targetUrl),
        headers: headers,
      );

      if (response.statusCode != 200) return [];

      final document = parser.parse(response.body);
      
      // We use a broader selector to catch different versions of the reader layout
      final images = document.querySelectorAll('img');

      final pageUrls = images
          .map((img) {
            // Check for common lazy-loading attributes first
            return img.attributes['data-src'] ?? 
                   img.attributes['data-lazy-src'] ?? 
                   img.attributes['src'] ?? '';
          })
          .where((src) => src.isNotEmpty && (src.contains('.jpg') || src.contains('.png') || src.contains('.webp')))
          .toList();

      return pageUrls;
    } catch (e) {
      debugPrint('Error fetching chapter pages: $e');
      return [];
    }
  }
}
