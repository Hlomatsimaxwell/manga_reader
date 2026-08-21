import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum ListMode { compact, details, grid }

class RelatedMangaScreen extends StatefulWidget {
  final String title;

  const RelatedMangaScreen({
    super.key,
    this.title = 'Related manga',
  });

  @override
  State<RelatedMangaScreen> createState() => _RelatedMangaScreenState();
}

class _RelatedMangaScreenState extends State<RelatedMangaScreen> {
  ListMode _selectedMode = ListMode.grid;
  double _gridSize = 3.0; // 2, 3, or 4 columns

  final List<Map<String, String>> _relatedItems = const [
    {
      'title': 'Record of Demon Annihilation',
      'imageUrl':
          'https://uploads.mangadex.org/covers/32d76d19-8a05-4db0-9fc2-e0b0648fe9d0/38f0d8bd-6750-482d-bfce-4c12bb1479fa.jpg',
      'subtitle': 'Chapter 45 • Ongoing',
    },
    {
      'title': 'A Substitute Bride to the Reaper D...',
      'imageUrl':
          'https://uploads.mangadex.org/covers/5a6f2382-628e-4a30-8a18-50ed27b400eb/6e8869c6-1e64-4e78-bebf-5f935f8a0711.jpg',
      'subtitle': 'Chapter 12 • Ongoing',
    },
    {
      'title': 'Reincarnation of the Fist King',
      'imageUrl':
          'https://uploads.mangadex.org/covers/32d76d19-8a05-4db0-9fc2-e0b0648fe9d0/38f0d8bd-6750-482d-bfce-4c12bb1479fa.jpg',
      'subtitle': 'Chapter 108 • Ongoing',
    },
    {
      'title': 'The Hounds of Sisyphus',
      'imageUrl':
          'https://uploads.mangadex.org/covers/5a6f2382-628e-4a30-8a18-50ed27b400eb/6e8869c6-1e64-4e78-bebf-5f935f8a0711.jpg',
      'subtitle': 'Chapter 88 • Completed',
    },
    {
      'title': 'The Divine Witch Will Find ...',
      'imageUrl':
          'https://uploads.mangadex.org/covers/32d76d19-8a05-4db0-9fc2-e0b0648fe9d0/38f0d8bd-6750-482d-bfce-4c12bb1479fa.jpg',
      'subtitle': 'Chapter 24 • Ongoing',
    },
    {
      'title': 'I Became the Scoundrel of the...',
      'imageUrl':
          'https://uploads.mangadex.org/covers/5a6f2382-628e-4a30-8a18-50ed27b400eb/6e8869c6-1e64-4e78-bebf-5f935f8a0711.jpg',
      'subtitle': 'Chapter 73 • Ongoing',
    },
    {
      'title': 'Necromancer of a Prestigious ...',
      'imageUrl':
          'https://uploads.mangadex.org/covers/32d76d19-8a05-4db0-9fc2-e0b0648fe9d0/38f0d8bd-6750-482d-bfce-4c12bb1479fa.jpg',
      'subtitle': 'Chapter 15 • Ongoing',
    },
  ];

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
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
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
          itemCount: _relatedItems.length,
          itemBuilder: (context, index) {
            final item = _relatedItems[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: item['imageUrl']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['title']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        );

      case ListMode.compact:
      case ListMode.details:
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _relatedItems.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _relatedItems[index];
            final isDetails = _selectedMode == ListMode.details;

            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item['imageUrl']!,
                    width: isDetails ? 60 : 45,
                    height: isDetails ? 80 : 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isDetails) ...[
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle']!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
    }
  }
}