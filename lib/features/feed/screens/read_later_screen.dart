import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';

class ReadLaterScreen extends StatefulWidget {
  const ReadLaterScreen({super.key});

  @override
  State<ReadLaterScreen> createState() => _ReadLaterScreenState();
}

class _ReadLaterScreenState extends State<ReadLaterScreen> {
  // Mock Read Later Bookmarks Data
  final List<Map<String, dynamic>> _readLaterList = [
    {
      'mangaId': 'rl_1',
      'title': 'Initializing the Sect System',
      'coverUrl': 'https://picsum.photos/seed/sect1/300/450',
      'author': 'Author A',
      'unreadCount': 12,
      'addedDate': 'Added 2 days ago',
      'source': 'ComicK',
    },
    {
      'mangaId': 'rl_2',
      'title': 'Return of the Mount Hua Sect',
      'coverUrl': 'https://picsum.photos/seed/mthua/300/450',
      'author': 'Biga',
      'unreadCount': 4,
      'addedDate': 'Added 1 week ago',
      'source': 'MangaDex',
    },
    {
      'mangaId': 'rl_3',
      'title': 'Solo Leveling',
      'coverUrl': 'https://picsum.photos/seed/manga3/300/450',
      'author': 'Chugong',
      'unreadCount': 0,
      'addedDate': 'Added 2 weeks ago',
      'source': 'Asura Scans',
    },
  ];

  void _removeItem(int index) {
    final removed = _readLaterList[index];
    setState(() {
      _readLaterList.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2C2C2E),
        content: Text(
          'Removed "${removed['title']}" from Read Later',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.blueAccent,
          onPressed: () {
            setState(() {
              _readLaterList.insert(index, removed);
            });
          },
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
        title: const Text(
          'Read later',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _readLaterList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your Read Later list is empty',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _readLaterList.length,
              itemBuilder: (context, index) {
                final item = _readLaterList[index];
                final unreadCount = item['unreadCount'] as int;

                return Dismissible(
                  key: Key(item['mangaId']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeItem(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MangaDetailScreen(
                              mangaId: item['mangaId'],
                              title: item['title'],
                              imageUrl: item['coverUrl'],
                            ),
                          ),
                        );
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item['coverUrl'],
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF2C2C2E),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        item['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['author']} • ${item['source']}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['addedDate'],
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8B1B1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount unread',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}