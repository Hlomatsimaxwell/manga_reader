import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/data/providers/sources_provider.dart';

class ManageSourcesScreen extends ConsumerStatefulWidget {
  const ManageSourcesScreen({super.key});

  @override
  ConsumerState<ManageSourcesScreen> createState() => _ManageSourcesScreenState();
}

class _ManageSourcesScreenState extends ConsumerState<ManageSourcesScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _disableNSFW = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourcesProvider);

    final filteredSources = sources.where((source) {
      if (_searchQuery.isEmpty) return true;
      return source['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.white,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search sources...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'Manage sources',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF2C2C2E),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, setPopupState) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _disableNSFW = !_disableNSFW;
                          });
                          setPopupState(() {});
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Disable NSFW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            Checkbox(
                              value: _disableNSFW,
                              activeColor: Colors.white,
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white70),
                              onChanged: (bool? val) {
                                setState(() {
                                  _disableNSFW = val ?? false;
                                });
                                setPopupState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredSources.length,
        itemBuilder: (context, index) {
          final source = filteredSources[index];
          final sourceName = source['name'] as String;
          final isPinned = source['isPinned'] == true;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: source['bgColor'] as Color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  source['text'] as String,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: source['textColor'] as Color? ?? Colors.white,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                if (isPinned) ...[
                  const Icon(
                    Icons.push_pin,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    sourceName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              source['language'] as String,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
            trailing: PopupMenuButton<String>(
              color: const Color(0xFF2C2C2E),
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'top') {
                  ref.read(sourcesProvider.notifier).moveToTop(sourceName);
                } else if (value == 'pin') {
                  ref.read(sourcesProvider.notifier).togglePin(sourceName);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'top',
                    child: Text(
                      'To top',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'pin',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pin',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        Icon(
                          isPinned
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'shortcut',
                    child: Text(
                      'Create shortcut',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Text(
                      'Settings',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ];
              },
            ),
          );
        },
      ),
    );
  }
}