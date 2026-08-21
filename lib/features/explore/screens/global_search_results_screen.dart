import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/sources/providers/sources_provider.dart';

enum SortOption { simple, name, author, genre }

class GlobalSearchResultsScreen extends ConsumerStatefulWidget {
  final String searchQuery;

  const GlobalSearchResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  ConsumerState<GlobalSearchResultsScreen> createState() =>
      _GlobalSearchResultsScreenState();
}

class _GlobalSearchResultsScreenState
    extends ConsumerState<GlobalSearchResultsScreen> {
  late TextEditingController _searchController;
  late String _activeQuery;

  // Filter & Sort States
  SortOption _selectedSort = SortOption.simple;
  bool _pinnedSourcesOnly = false;
  bool _hideEmptySources = false;

  final List<Map<String, dynamic>> _allSources = const [
    {
      'sourceName': 'ComicK',
      'hasServerError': false,
      'serverErrorMessage': '',
      'mangaList': [
        {
          'id': 'cm_1',
          'title': 'Fire Force',
          'coverUrl': 'https://picsum.photos/seed/ff1/300/450',
          'author': 'Atsushi Ohkubo',
          'genre': 'Action',
        },
        {
          'id': 'cm_2',
          'title': 'Fire Brigade of Flames',
          'coverUrl': 'https://picsum.photos/seed/ff2/300/450',
          'author': 'Atsushi Ohkubo',
          'genre': 'Action',
        },
      ],
    },
    {
      'sourceName': 'MangaDex',
      'hasServerError': false,
      'serverErrorMessage': '',
      'mangaList': [
        {
          'id': 'md_1',
          'title': 'Enen no Shouboutai (Fire Force)',
          'coverUrl': 'https://picsum.photos/seed/ff3/300/450',
          'author': 'Atsushi Ohkubo',
          'genre': 'Action',
        },
        {
          'id': 'md_2',
          'title': 'En\'en no Shouboutai',
          'coverUrl': 'https://picsum.photos/seed/ff4/300/450',
          'author': 'Atsushi Ohkubo',
          'genre': 'Action',
        },
        {
          'id': 'md_3',
          'title': 'Flag Capture in the First Move',
          'coverUrl': 'https://picsum.photos/seed/ff5/300/450',
          'author': 'Unknown',
          'genre': 'Comedy',
        },
      ],
    },
    {
      'sourceName': 'MangaFire (English)',
      'hasServerError': false,
      'serverErrorMessage': '',
      'mangaList': [
        {
          'id': 'mf_1',
          'title': 'Fire Punch',
          'coverUrl': 'https://picsum.photos/seed/fp1/300/450',
          'author': 'Tatsuki Fujimoto',
          'genre': 'Drama',
        },
        {
          'id': 'mf_2',
          'title': 'Fire Train',
          'coverUrl': 'https://picsum.photos/seed/ft1/300/450',
          'author': 'Author B',
          'genre': 'Mystery',
        },
        {
          'id': 'mf_3',
          'title': 'Fire Candy',
          'coverUrl': 'https://picsum.photos/seed/fc1/300/450',
          'author': 'Author C',
          'genre': 'Romance',
        },
      ],
    },
    {
      'sourceName': 'AyaToon',
      'hasServerError': true,
      'serverErrorMessage':
          'Read error: ssl=0xb400007c3c887418: Failure in SSL library, usually a protocol error',
      'mangaList': <Map<String, String>>[],
    },
    {
      'sourceName': 'DragonTea',
      'hasServerError': true,
      'serverErrorMessage':
          'You are blocked by the server. Try to use a different network connection (VPN, Proxy, etc.)',
      'mangaList': <Map<String, String>>[],
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeQuery = widget.searchQuery;
    _searchController = TextEditingController(text: _activeQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRadioOption('Simple', SortOption.simple, setDialogState),
                    _buildRadioOption('Name', SortOption.name, setDialogState),
                    _buildRadioOption('Author', SortOption.author, setDialogState),
                    _buildRadioOption('Genre', SortOption.genre, setDialogState),
                    const Divider(color: Colors.white24, height: 16),
                    _buildCheckboxOption(
                      'Pinned sources only',
                      _pinnedSourcesOnly,
                      (val) {
                        setDialogState(() => _pinnedSourcesOnly = val);
                        setState(() {});
                      },
                    ),
                    _buildCheckboxOption(
                      'Hide empty sources',
                      _hideEmptySources,
                      (val) {
                        setDialogState(() => _hideEmptySources = val);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption(
      String title, SortOption option, StateSetter setDialogState) {
    return RadioListTile<SortOption>(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      value: option,
      groupValue: _selectedSort,
      activeColor: Colors.white,
      onChanged: (SortOption? val) {
        if (val != null) {
          setDialogState(() => _selectedSort = val);
          setState(() {});
        }
      },
    );
  }

  Widget _buildCheckboxOption(
      String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      value: value,
      activeColor: Colors.white,
      checkColor: Colors.black,
      side: const BorderSide(color: Colors.white70),
      onChanged: (bool? val) {
        if (val != null) onChanged(val);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final queryLower = _activeQuery.toLowerCase().trim();
    final sourcesState = ref.watch(sourcesProvider);

    // Filter sources list
    final displayedSources = _allSources.where((source) {
      final String sourceName = source['sourceName'];
      final bool hasServerError = source['hasServerError'];
      final List<Map<String, String>> mangaList = source['mangaList'];

      // Match query
      final matches = mangaList
          .where((m) => m['title']!.toLowerCase().contains(queryLower))
          .toList();

      // Check pinned state from Riverpod provider
      final providerSource = sourcesState.firstWhere(
        (s) => s['name'] == sourceName,
        orElse: () => {'isPinned': false},
      );
      final isPinned = providerSource['isPinned'] == true;

      // Filter: Pinned sources only
      if (_pinnedSourcesOnly && !isPinned) return false;

      // Filter: Hide empty sources
      if (_hideEmptySources && (hasServerError || matches.isEmpty)) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: Colors.white,
          textInputAction: TextInputAction.search,
          onSubmitted: (val) => setState(() => _activeQuery = val),
          decoration: const InputDecoration(
            hintText: 'Search manga...',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 16),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterMenu(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Search results for "$_activeQuery"',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: displayedSources.length,
              itemBuilder: (context, index) {
                final source = displayedSources[index];
                final String sourceName = source['sourceName'];
                final bool hasServerError = source['hasServerError'];
                final String serverErrorMessage = source['serverErrorMessage'];
                final List<Map<String, String>> mangaList = source['mangaList'];

                // Filter & Sort manga list
                var matchingManga = mangaList
                    .where((m) => m['title']!.toLowerCase().contains(queryLower))
                    .toList();

                if (_selectedSort == SortOption.name) {
                  matchingManga.sort((a, b) => a['title']!.compareTo(b['title']!));
                } else if (_selectedSort == SortOption.author) {
                  matchingManga.sort((a, b) => (a['author'] ?? '')
                      .compareTo(b['author'] ?? ''));
                } else if (_selectedSort == SortOption.genre) {
                  matchingManga.sort((a, b) => (a['genre'] ?? '')
                      .compareTo(b['genre'] ?? ''));
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sourceName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!hasServerError && matchingManga.isNotEmpty)
                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Show all',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (hasServerError)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  serverErrorMessage,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (matchingManga.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Content not found or removed',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: matchingManga.length,
                            itemBuilder: (context, itemIdx) {
                              final item = matchingManga[itemIdx];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MangaDetailScreen(
                                        mangaId: item['id']!,
                                        title: item['title']!,
                                        imageUrl: item['coverUrl']!,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          item['coverUrl']!,
                                          height: 140,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['title']!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}