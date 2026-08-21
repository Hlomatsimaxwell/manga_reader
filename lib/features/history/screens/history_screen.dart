import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manga_reader/features/explore/screens/global_search_screen.dart';
import 'package:manga_reader/features/library/screens/manga_detail_screen.dart';
import 'package:manga_reader/features/settings/screens/settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilter =
      -1; // -1: none, 0: On device, 1: New chapters, 2: Completed

  bool _isIncognitoMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Persistent option default states
  String _listMode = 'Grid'; // 'Compact', 'Details', 'Grid'
  double _gridSize = 3; // Grid columns (1 to 6)
  String _sortingOrder = 'Last read';
  bool _isGrouped = true;

  final List<String> _sortOptions = [
    'Added',
    'Oldest',
    'Progress',
    'Unread',
    'Name',
    'Name reversed',
    'New chapters',
    'Last read',
    'Long time ago read',
    'Updated',
  ];

  final List<Map<String, dynamic>> _historyItems = [
    {
      'mangaId': 'manga_1',
      'title': 'Return of the Mad Demon',
      'lastReadChapter': 209,
      'dateGroup': 'July 31',
      'coverUrl': 'https://picsum.photos/seed/manga1/300/450',
      'progress': 99,
      'unreadCount': 1,
      'isFavorite': true,
    },
    {
      'mangaId': 'manga_2',
      'title': 'THE MASTERS ARE ...',
      'lastReadChapter': 14,
      'dateGroup': 'July 29',
      'coverUrl': 'https://picsum.photos/seed/manga2/300/450',
      'progress': 17,
      'unreadCount': 0,
      'isFavorite': false,
    },
    {
      'mangaId': 'manga_3',
      'title': 'Solo Leveling',
      'lastReadChapter': 1,
      'dateGroup': 'July 29',
      'coverUrl': 'https://picsum.photos/seed/manga3/300/450',
      'progress': 0,
      'unreadCount': 0,
      'isFavorite': false,
    },
    {
      'mangaId': 'manga_4',
      'title': 'The Masters Are Subscribing To ...',
      'lastReadChapter': 12,
      'dateGroup': 'July 29',
      'coverUrl': 'https://picsum.photos/seed/manga4/300/450',
      'progress': 0,
      'unreadCount': 0,
      'isFavorite': true,
    },
    {
      'mangaId': 'manga_5',
      'title': 'Absolute Sword Sense',
      'lastReadChapter': 98,
      'dateGroup': 'July 19',
      'coverUrl': 'https://picsum.photos/seed/manga5/300/450',
      'progress': 98,
      'unreadCount': 2,
      'isFavorite': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _listMode = prefs.getString('history_list_mode') ?? 'Grid';
      _gridSize = prefs.getDouble('history_grid_size') ?? 3.0;
      _sortingOrder = prefs.getString('history_sorting_order') ?? 'Last read';
      _isGrouped = prefs.getBool('history_is_grouped') ?? true;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is bool) await prefs.setBool(key, value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> item) {
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
  }

  void _showClearHistoryDialog(BuildContext context) {
    int selectedOption = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.only(top: 20, bottom: 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Clear history',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRadioOption(
                    title: 'Last 2 hours',
                    value: 0,
                    groupValue: selectedOption,
                    onChanged: (val) =>
                        setDialogState(() => selectedOption = val!),
                  ),
                  _buildRadioOption(
                    title: 'Today',
                    value: 1,
                    groupValue: selectedOption,
                    onChanged: (val) =>
                        setDialogState(() => selectedOption = val!),
                  ),
                  _buildRadioOption(
                    title: 'Not in favorites',
                    value: 2,
                    groupValue: selectedOption,
                    onChanged: (val) =>
                        setDialogState(() => selectedOption = val!),
                  ),
                  _buildRadioOption(
                    title: 'Clear all history',
                    value: 3,
                    groupValue: selectedOption,
                    onChanged: (val) =>
                        setDialogState(() => selectedOption = val!),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History cleared')),
                    );
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption({
    required String title,
    required int value,
    required int groupValue,
    required ValueChanged<int?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: groupValue,
              activeColor: Colors.white,
              fillColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.white70;
              }),
              onChanged: onChanged,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showListOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'List mode',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      children: [
                        _buildSegmentTab(
                          'Compact',
                          Icons.format_list_bulleted,
                          setSheetState,
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: Colors.white24,
                          indent: 8,
                          endIndent: 8,
                        ),
                        _buildSegmentTab(
                          'Details',
                          Icons.view_list,
                          setSheetState,
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: Colors.white24,
                          indent: 8,
                          endIndent: 8,
                        ),
                        _buildSegmentTab(
                          'Grid',
                          Icons.grid_view_rounded,
                          setSheetState,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grid size',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_gridSize.toInt()} Columns',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                        elevation: 4,
                      ),
                      overlayColor: Colors.white.withOpacity(0.12),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20,
                      ),
                      tickMarkShape: const RoundSliderTickMarkShape(
                        tickMarkRadius: 2,
                      ),
                      activeTickMarkColor: Colors.transparent,
                      inactiveTickMarkColor: Colors.white30,
                    ),
                    child: Slider(
                      value: 7 - _gridSize,
                      min: 1,
                      max: 6,
                      divisions: 5,
                      onChanged: (value) {
                        final actualColumns = 7 - value;

                        setSheetState(() {
                          _gridSize = actualColumns;
                        });
                        setState(() {});
                        _savePreference('history_grid_size', actualColumns);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sorting order',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortingOrder,
                        dropdownColor: const Color(0xFF2C2C2E),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        items: _sortOptions.map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue == null) return;

                          setSheetState(() {
                            _sortingOrder = newValue;
                          });
                          setState(() {});
                          _savePreference('history_sorting_order', newValue);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.format_list_bulleted,
                            color: Colors.white70,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Group',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isGrouped,
                        activeColor: Colors.black,
                        activeTrackColor: Colors.white,
                        inactiveThumbColor: Colors.white54,
                        inactiveTrackColor: const Color(0xFF2C2C2E),
                        onChanged: (value) {
                          setSheetState(() {
                            _isGrouped = value;
                          });
                          setState(() {});
                          _savePreference('history_is_grouped', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSegmentTab(
    String mode,
    IconData icon,
    StateSetter setSheetState,
  ) {
    final isSelected = _listMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setSheetState(() => _listMode = mode);
          setState(() {});
          _savePreference('history_list_mode', mode);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B6F76) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 2),
              Text(
                mode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOverflowMenu(BuildContext context, Offset offset) async {
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      MediaQuery.of(context).size.width - offset.dx,
      MediaQuery.of(context).size.height - offset.dy,
    );

    await showMenu(
      context: context,
      position: position,
      color: const Color(0xFF2C2C2E),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _showClearHistoryDialog(context);
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Clear history',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _showListOptionsSheet(context);
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'List options',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        PopupMenuItem(
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Statistics',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        PopupMenuItem(
          onTap: () {
            setState(() {
              _isIncognitoMode = !_isIncognitoMode;
            });
          },
          child: StatefulBuilder(
            builder: (context, setMenuState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Incognito mode',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Checkbox(
                    value: _isIncognitoMode,
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                    side: const BorderSide(color: Colors.white70, width: 2),
                    onChanged: (bool? value) {
                      setState(() {
                        _isIncognitoMode = value ?? false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _historyItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item['title'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    filteredList.sort((a, b) {
      if (_sortingOrder == 'Name') {
        return a['title'].toString().compareTo(b['title'].toString());
      } else if (_sortingOrder == 'Name reversed') {
        return b['title'].toString().compareTo(a['title'].toString());
      } else if (_sortingOrder == 'Progress') {
        return (b['progress'] as int).compareTo(a['progress'] as int);
      } else if (_sortingOrder == 'Unread') {
        return (b['unreadCount'] as int).compareTo(a['unreadCount'] as int);
      }
      return 0;
    });

    final Map<String, List<Map<String, dynamic>>> groupedHistory = {};
    if (_isGrouped) {
      for (var item in filteredList) {
        final date = item['dateGroup'] as String;
        groupedHistory.putIfAbsent(date, () => []).add(item);
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 16),
              if (filteredList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      'No reading history found',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                )
              else if (_isGrouped)
                ...groupedHistory.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildHistoryLayout(context, entry.value),
                      const SizedBox(height: 12),
                    ],
                  );
                })
              else
                _buildHistoryLayout(context, filteredList),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalSearchScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14),
                color: Colors.transparent,
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white70, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search manga',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTapDown: (TapDownDetails details) {
              _showOverflowMenu(context, details.globalPosition);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              color: Colors.transparent,
              child: const Icon(
                Icons.more_vert,
                color: Colors.white70,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'icon': Icons.sd_card_outlined, 'label': 'On device'},
      {'icon': Icons.history_toggle_off, 'label': 'New chapters'},
      {'icon': Icons.done_all, 'label': 'Completed'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = isSelected ? -1 : index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white38,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHistoryLayout(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    if (_listMode == 'Compact') {
      return _buildCompactList(context, items);
    } else if (_listMode == 'Details') {
      return _buildDetailsList(context, items);
    } else {
      return _buildGridSection(context, items);
    }
  }

  Widget _buildCompactList(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: item['coverUrl'],
              width: 40,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            item['title'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Ch. ${item['lastReadChapter']}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: Text(
            '${item['progress']}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => _navigateToDetail(context, item),
        );
      },
    );
  }

  Widget _buildDetailsList(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToDetail(context, item),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item['coverUrl'],
                      width: 60,
                      height: 85,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Last read: Chapter ${item['lastReadChapter']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (item['progress'] as int) / 100,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridSection(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridSize.toInt(),
          childAspectRatio: _gridSize >= 5
              ? 0.40
              : _gridSize >= 4
                  ? 0.45
                  : 0.54,
          crossAxisSpacing: 10,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMangaPosterCard(context, item);
        },
      ),
    );
  }

  Widget _buildMangaPosterCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final progress = item['progress'] as int;
    final unreadCount = item['unreadCount'] as int;
    final isFavorite = item['isFavorite'] == true;
    final bool isCompactGrid = _gridSize >= 4;

    return GestureDetector(
      onTap: () => _navigateToDetail(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item['coverUrl'],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF2C2C2E),
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  right: 4,
                  child: Row(
                    children: [
                      if (unreadCount > 0)
                        Container(
                          padding: EdgeInsets.all(isCompactGrid ? 3 : 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0A8A8),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isCompactGrid ? 8 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isFavorite && !isCompactGrid) ...[
                        const SizedBox(width: 2),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 9,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactGrid ? 4 : 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$progress%',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: isCompactGrid ? 8 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              item['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompactGrid ? 9 : 11,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KotatsuSliderThumbShape extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;

  const KotatsuSliderThumbShape({this.thumbWidth = 4, this.thumbHeight = 28});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final rect = Rect.fromCenter(
      center: center,
      width: thumbWidth,
      height: thumbHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);
  }
}