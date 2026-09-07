import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/data/providers/sources_provider.dart';
import 'package:yomou/core/widgets/ios/ios_menu.dart';

class ManageSourcesScreen extends ConsumerStatefulWidget {
  const ManageSourcesScreen({super.key});

  @override
  ConsumerState<ManageSourcesScreen> createState() =>
      _ManageSourcesScreenState();
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final sources = ref.watch(sourcesProvider);

    final filteredSources = sources.where((source) {
      if (_searchQuery.isEmpty) return true;
      return source['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: dark ? Colors.white : const Color(0xFF1C1B1F),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF1C1B1F),
                  fontSize: 18,
                ),
                cursorColor: dark ? Colors.white : const Color(0xFF1C1B1F),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search sources...',
                  hintStyle: TextStyle(
                    color: dark ? Colors.white54 : Colors.black54,
                  ),
                  border: InputBorder.none,
                ),
              )
            : Text(
                'Manage sources',
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF1C1B1F),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: dark ? Colors.white : const Color(0xFF1C1B1F),
            ),
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
          AppSheetPress(
            onTap: () {
              showIosMenuPanel(
                context,
                children: [
                  MenuToggleRow(
                    label: 'Disable NSFW',
                    value: _disableNSFW,
                    onChanged: (v) => setState(() => _disableNSFW = v),
                  ),
                ],
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.more_horiz_rounded,
                color: (dark ? Colors.white : const Color(0xFF1C1B1F))
                    .withValues(alpha: 0.8),
              ),
            ),
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
            // --- ADDED ONTAP LOGIC HERE ---
            onTap: () {
              // 1. Switch the active source using our new registry
              ref.read(currentSourceProvider.notifier).state = getSourceByName(
                sourceName,
              );

              // 2. Show a a nice confirmation to the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to $sourceName'),
                  backgroundColor: source['bgColor'] as Color,
                  duration: const Duration(seconds: 1),
                ),
              );

              // 3. Go back to the home screen to see the new content
              Navigator.pop(context);
            },
            // ------------------------------
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
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
                  Icon(
                    Icons.push_pin,
                    color: dark ? Colors.white : scheme.onSurface,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    sourceName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark ? Colors.white : scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              source['language'] as String,
              style: TextStyle(
                color: dark ? Colors.white54 : Colors.black54,
                fontSize: 13,
              ),
            ),
            trailing: IosMenuButton<String>(
              items: [
                const IosMenuItem(
                  value: 'top',
                  label: 'To top',
                  icon: Icons.vertical_align_top_rounded,
                ),
                IosMenuItem(
                  value: 'pin',
                  label: 'Pin',
                  icon: isPinned
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                const IosMenuItem(
                  value: 'shortcut',
                  label: 'Create shortcut',
                  icon: Icons.launch_rounded,
                ),
                const IosMenuItem(
                  value: 'settings',
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                ),
              ],
              onSelected: (value) {
                if (value == 'top') {
                  ref.read(sourcesProvider.notifier).moveToTop(sourceName);
                } else if (value == 'pin') {
                  ref.read(sourcesProvider.notifier).togglePin(sourceName);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
