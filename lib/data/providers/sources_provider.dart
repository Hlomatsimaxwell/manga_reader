import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_source.dart';
import '../sources/manganato_service.dart';
import '../sources/mock_source.dart';
import '../sources/anime_api_source.dart'; // <--- ADDED THIS IMPORT

// 1. THE SOURCE REGISTRY
// This maps the "Name" in your UI list to the "Actual Code"
MangaSource getSourceByName(String name) {
  switch (name) {
    case 'Anime-API': // <--- ADDED THIS CASE
      return AnimeApiSource();
    case 'Manganato':
      return ManganatoService();
    case 'Mock Source':
      return MockSource();
    default:
      return ManganatoService(); // Fallback
  }
}

// 2. DYNAMIC ACTIVE SOURCE
final currentSourceProvider = StateProvider<MangaSource>((ref) {
  // I've set the default to Anime-API so you can see it working immediately!
  return AnimeApiSource(); 
});

class SourcesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  SourcesNotifier() : super(_defaultSources) {
    _loadFromPrefs();
  }

  static const String _prefsKey = 'pinned_sources_list';

  static final List<Map<String, dynamic>> _defaultSources = [
    {
      'name': 'Anime-API', // <--- ADDED THIS TO UI LIST
      'language': 'English',
      'bgColor': const Color(0xFF6200EE),
      'text': 'A',
      'isPinned': true,
    },
    {
      'name': 'Manganato', 
      'language': 'English',
      'bgColor': const Color(0xFFE67E22),
      'text': 'M',
      'isPinned': true,
    },
    {
      'name': 'Mock Source', 
      'language': 'Mock',
      'bgColor': const Color(0xFF95A5A6),
      'text': '?',
      'isPinned': false,
    },
    {
      'name': 'ComicK',
      'language': 'Manga, Various languages',
      'bgColor': const Color(0xFF2C2C2E),
      'text': '🦄',
      'isPinned': false,
    },
    {
      'name': 'MangaDex',
      'language': 'Manga, Various languages',
      'bgColor': const Color(0xFF381F1D),
      'text': '🐱',
      'textColor': Colors.orangeAccent,
      'isPinned': false,
    },
  ];

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedJson = prefs.getString(_prefsKey);

    if (savedJson != null) {
      final List<dynamic> decoded = jsonDecode(savedJson);
      final pinnedMap = <String, bool>{};

      for (var item in decoded) {
        pinnedMap[item['name']] = item['isPinned'] ?? false;
      }

      final updatedList = state.map((source) {
        final name = source['name'] as String;
        return {
          ...source,
          'isPinned': pinnedMap[name] ?? false,
        };
      }).toList();

      state = _sortSources(updatedList);
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final dataToSave = state
        .map((source) => {
              'name': source['name'],
              'isPinned': source['isPinned'],
            })
        .toList();

    await prefs.setString(_prefsKey, jsonEncode(dataToSave));
  }

  void togglePin(String sourceName) {
    final updatedList = state.map((source) {
      if (source['name'] == sourceName) {
        final currentPinned = source['isPinned'] == true;
        return {...source, 'isPinned': !currentPinned};
      }
      return source;
    }).toList();

    state = _sortSources(updatedList);
    _saveToPrefs();
  }

  void moveToTop(String sourceName) {
    final index = state.indexWhere((s) => s['name'] == sourceName);
    if (index != -1) {
      final item = state[index];
      final newList = List<Map<String, dynamic>>.from(state)..removeAt(index);
      newList.insert(0, item);
      state = newList;
      _saveToPrefs();
    }
  }

  List<Map<String, dynamic>> _sortSources(List<Map<String, dynamic>> list) {
    final pinned = list.where((s) => s['isPinned'] == true).toList();
    final unpinned = list.where((s) => s['isPinned'] != true).toList();
    return [...pinned, ...unpinned];
  }
}

final sourcesProvider =
    StateNotifierProvider<SourcesNotifier, List<Map<String, dynamic>>>((ref) {
  return SourcesNotifier();
});
