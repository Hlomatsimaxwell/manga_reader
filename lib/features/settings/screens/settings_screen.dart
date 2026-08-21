import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
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
            onTap: () {},
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}