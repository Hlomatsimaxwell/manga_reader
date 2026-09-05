import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/data/models/manga.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/library/widgets/downloaded_badge.dart';

enum ListMode { compact, details, grid }

class RelatedMangaScreen extends StatefulWidget {
  final String title;
  final List<Manga>? relatedManga;

  const RelatedMangaScreen({
    super.key,
    this.title = 'Related manga',
    this.relatedManga,
  });

  @override
  State<RelatedMangaScreen> createState() => _RelatedMangaScreenState();
}

class _RelatedMangaScreenState extends State<RelatedMangaScreen> {
  ListMode _selectedMode = ListMode.grid;
  double _gridSize = 3.0; // 2, 3, or 4 columns

  final List<Manga> _fallbackItems = [
    Manga(
      id: '1',
      sourceId: 'mock',
      title: 'Record of Demon Annihilation',
      coverUrl: 'https://picsum.photos/seed/rel1/300/450',
    ),
    Manga(
      id: '2',
      sourceId: 'mock',
      title: 'A Substitute Bride to the Reaper D...',
      coverUrl: 'https://picsum.photos/seed/rel2/300/450',
    ),
    Manga(
      id: '3',
      sourceId: 'mock',
      title: 'Reincarnation of the Fist King',
      coverUrl: 'https://picsum.photos/seed/rel3/300/450',
    ),
    Manga(
      id: '4',
      sourceId: 'mock',
      title: 'The Hounds of Sisyphus',
      coverUrl: 'https://picsum.photos/seed/rel4/300/450',
    ),
    Manga(
      id: '5',
      sourceId: 'mock',
      title: 'The Divine Witch Will Find ...',
      coverUrl: 'https://picsum.photos/seed/rel5/300/450',
    ),
    Manga(
      id: '6',
      sourceId: 'mock',
      title: 'I Became the Scoundrel of the...',
      coverUrl: 'https://picsum.photos/seed/rel6/300/450',
    ),
    Manga(
      id: '7',
      sourceId: 'mock',
      title: 'Necromancer of a Prestigious ...',
      coverUrl: 'https://picsum.photos/seed/rel7/300/450',
    ),
  ];

  List<Manga> get _items =>
      (widget.relatedManga != null && widget.relatedManga!.isNotEmpty)
      ? widget.relatedManga!
      : _fallbackItems;

  void _showListOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'List mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Segmented Mode Selector
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildModeButton(
                          label: 'Compact',
                          icon: Icons.reorder_rounded,
                          mode: ListMode.compact,
                          setSheetState: setSheetState,
                        ),
                        _buildModeButton(
                          label: 'Details',
                          icon: Icons.format_list_bulleted_rounded,
                          mode: ListMode.details,
                          setSheetState: setSheetState,
                        ),
                        _buildModeButton(
                          label: 'Grid',
                          icon: Icons.grid_view_rounded,
                          mode: ListMode.grid,
                          setSheetState: setSheetState,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grid Size Slider
                  if (_selectedMode == ListMode.grid) ...[
                    const Text(
                      'Grid size',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white12,
                        trackHeight: 12,
                      ),
                      child: Slider(
                        value: _gridSize,
                        min: 2.0,
                        max: 4.0,
                        divisions: 2,
                        onChanged: (val) {
                          setSheetState(() => _gridSize = val);
                          setState(() => _gridSize = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required ListMode mode,
    required StateSetter setSheetState,
  }) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setSheetState(() => _selectedMode = mode);
          setState(() => _selectedMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3A3A3C) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2C2C2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'options') {
                _showListOptionsBottomSheet();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'options',
                child: Text(
                  'List options',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    final items = _items;
    switch (_selectedMode) {
      case ListMode.grid:
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize.toInt(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.58,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () => _openManga(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: item.coverUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF2C2C2E),
                              child: const Icon(
                                Icons.menu_book,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ),
                        DownloadedMangaBadge(mangaId: item.id),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case ListMode.compact:
      case ListMode.details:
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final isDetails = _selectedMode == ListMode.details;

            return GestureDetector(
              onTap: () => _openManga(item),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: item.coverUrl,
                          width: isDetails ? 60 : 45,
                          height: isDetails ? 80 : 60,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: isDetails ? 60 : 45,
                            height: isDetails ? 80 : 60,
                            color: const Color(0xFF2C2C2E),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                      DownloadedMangaBadge(
                        mangaId: item.id,
                        size: 16,
                        iconSize: 10,
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
    }
  }

  void _openManga(Manga manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailScreen(
          mangaId: manga.id,
          title: manga.title,
          imageUrl: manga.coverUrl,
          sourceId: manga.sourceId,
        ),
      ),
    );
  }
}
