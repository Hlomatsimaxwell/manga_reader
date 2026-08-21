import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'base_source.dart';
import 'package:manga_reader/features/sources/models/manga.dart';
import 'package:manga_reader/features/sources/models/chapter.dart' as app_chapter;

class ManganatoService implements BaseSource {
  static const String baseUrl = 'https://manganato.com';

  @override
  String get name => 'Manganato';

  @override
  Future<List<Manga>> getPopularManga({int page = 1}) async {
    final response = await http.get(Uri.parse('$baseUrl/genre-all/$page'));
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
        sourceId: 'manganato',
        title: titleEl?.text.trim() ?? '',
        coverUrl: imgEl?.attributes['src'] ?? '',
      );
    }).toList();
  }

  @override
  Future<List<app_chapter.Chapter>> getChapters(String mangaId) async {
    final response = await http.get(Uri.parse('$baseUrl/manga-$mangaId'));
    if (response.statusCode != 200) return [];

    final document = parser.parse(response.body);
    final elements = document.querySelectorAll('.row-content-chapter .a-h');

    return elements.map((element) {
      final url = element.attributes['href'] ?? '';
      final id = url.split('/').last;

      return app_chapter.Chapter(
        id: id,
        title: element.text.trim(),
        chapterNumber: element.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        releaseDate: '',
        url: url,
      );
    }).toList();
  }

  @override
  Future<List<String>> getPageList(app_chapter.Chapter chapter) async {
    return getPageUrls(chapter.id);
  }

 @override
Future<List<String>> getPageUrls(String chapterId) async {
  try {
    // Correctly construct the Manganato URL
    final String targetUrl;
    if (chapterId.startsWith('http')) {
      targetUrl = chapterId;
    } else if (chapterId.startsWith('chapter-')) {
      targetUrl = '$baseUrl/$chapterId';
    } else {
      targetUrl = '$baseUrl/chapter-$chapterId';
    }

    final response = await http.get(
      Uri.parse(targetUrl),
      headers: {
        'Referer': 'https://manganato.com/',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    );

    if (response.statusCode != 200) {
      debugPrint('Manganato page request failed with status: ${response.statusCode}');
      return [];
    }

    final document = parser.parse(response.body);
    final images = document.querySelectorAll(
      '.container-chapter-reader img, .vnv-content img, .container-reader-story img',
    );

    final pageUrls = images
        .map((img) => img.attributes['data-src'] ?? img.attributes['src'] ?? '')
        .where((src) => src.isNotEmpty)
        .toList();

    debugPrint('Fetched ${pageUrls.length} pages from $targetUrl');
    return pageUrls;
  } catch (e) {
    debugPrint('Error fetching chapter pages: $e');
    return [];
  }
}
}