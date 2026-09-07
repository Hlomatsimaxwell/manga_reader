import 'package:flutter/material.dart';
import 'package:yomou/features/settings/screens/appearance_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final appBarContentColor = dark ? Colors.white : const Color(0xFF1C1B1F);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarContentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: appBarContentColor),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSettingTile(
            context: context,
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme, List mode, Language',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppearanceSettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.collections_bookmark_outlined,
            title: 'Manga sources',
            subtitle: '1033 of 931 on',
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.menu_book_outlined,
            title: 'Reader settings',
            subtitle: 'Read mode, Scale mode, Switch pages',
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.pie_chart_outline_rounded,
            title: 'Storage and network',
            subtitle: 'Storage usage, Proxy, Content preloading',
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.file_download_outlined,
            title: 'Downloads',
            subtitle: 'Downloads folder, Download only via Wi-Fi',
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.rss_feed_rounded,
            title: 'Check for new chapters',
            subtitle: 'Look for updates, Notifications settings',
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.extension_outlined,
            title: 'Services',
            subtitle: 'Suggestions, Synchronization, Tracking',
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.history_rounded,
            title: 'Backup and restore',
            subtitle: 'Create or restore a backup, Periodic backups',
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'Version 9.8.1',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Icon(
          icon,
          color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface,
          size: 26,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(color: dark ? Colors.white54 : Colors.black54, fontSize: 14),
        ),
      ),
      onTap: onTap,
    );
  }
}
