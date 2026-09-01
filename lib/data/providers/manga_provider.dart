import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import 'sources_provider.dart';

final popularMangaProvider = FutureProvider<List<Manga>>((ref) async {
  final source = ref.watch(currentSourceProvider);
  return source.getPopularManga();
});