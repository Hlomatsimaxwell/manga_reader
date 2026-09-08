import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:yomou/l10n/generated/app_localizations.dart';
import 'package:yomou/features/settings/screens/appearance_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final appBarContentColor = dark ? Colors.white : const Color(0xFF1C1B1F);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(RemixIcons.arrow_left_line, color: appBarContentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.settings,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(RemixIcons.search_line, color: appBarContentColor),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSettingTile(
            context: context,
            icon: RemixIcons.palette_line,
            title: l.settingsAppearance,
            subtitle: l.settingsAppearanceSubtitle,
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
            icon: RemixIcons.bookmark_3_line,
            title: l.settingsMangaSources,
            subtitle: l.settingsMangaSourcesSubtitle,
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: RemixIcons.book_open_line,
            title: l.settingsReader,
            subtitle: l.settingsReaderSubtitle,
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: RemixIcons.pie_chart_2_line,
            title: l.settingsStorage,
            subtitle: l.settingsStorageSubtitle,
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: RemixIcons.download_line,
            title: l.settingsDownloads,
            subtitle: l.settingsDownloadsSubtitle,
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: RemixIcons.rss_line,
            title: l.settingsNewChapters,
            subtitle: l.settingsNewChaptersSubtitle,
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: RemixIcons.puzzle_2_line,
            title: l.settingsServices,
            subtitle: l.settingsServicesSubtitle,
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: RemixIcons.history_line,
            title: l.settingsBackup,
            subtitle: l.settingsBackupSubtitle,
            onTap: () {},
          ),
          _buildSettingTile(
            context: context,
            icon: RemixIcons.information_line,
            title: l.settingsAbout,
            subtitle: l.settingsAboutSubtitle,
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
