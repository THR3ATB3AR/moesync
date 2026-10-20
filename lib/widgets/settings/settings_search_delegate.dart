import 'package:flutter/material.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/screens/settings_screen.dart';

class SettingsSearchDelegate extends SearchDelegate<void> {
  SettingsSearchDelegate({required String searchFieldLabel})
    : super(searchFieldLabel: searchFieldLabel);

  List<SettingsSearchItem> searchableItems(BuildContext context) => [
    SettingsSearchItem(
      title: AppLocalizations.of(context).languageSettings,
      subtitle: AppLocalizations.of(context).languageSettingsDescription,
      categoryKey: 'language',
      icon: Icons.translate_rounded,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).appearance,
      subtitle: AppLocalizations.of(context).themeDisplayModeBadgeStyleLivePreview,
      categoryKey: 'appearance',
      icon: Icons.palette_outlined,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).layoutStyle,
      subtitle: AppLocalizations.of(context).gridOrListViewForAnimeAndManga,
      categoryKey: 'appearance',
      icon: Icons.dashboard_customize_rounded,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).displayStyleBadges,
      subtitle: AppLocalizations.of(context).pillTextOrIconBadgesWithLivePreview,
      categoryKey: 'appearance',
      icon: Icons.style_rounded,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).dataSourcesSync,
      subtitle: AppLocalizations.of(context).defaultInformationDescriptionAndSyncServices,
      categoryKey: 'sources',
      icon: Icons.hub_outlined,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).animeDataSourceDescription,
      subtitle: AppLocalizations.of(context).chooseDefaultInfoSynopsisAndSyncSourceForAnime,
      categoryKey: 'sources',
      icon: Icons.tv_rounded,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).mangaDataSourceDescription,
      subtitle: AppLocalizations.of(context).chooseDefaultInfoSynopsisAndSyncSourceForManga,
      categoryKey: 'sources',
      icon: Icons.auto_stories_rounded,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).trackingAccounts,
      subtitle: AppLocalizations.of(context).syncServicesAndAccountConnections,
      categoryKey: 'tracking',
      icon: Icons.sync_rounded,
    ),
    SettingsSearchItem(
      title: 'MyAnimeList',
      subtitle: AppLocalizations.of(context).connectAndManageMalCredentials,
      categoryKey: 'tracking',
      icon: Icons.cloud_done_rounded,
    ),
    SettingsSearchItem(
      title: 'AniList',
      subtitle: AppLocalizations.of(context).connectAndManageAnilistToken,
      categoryKey: 'tracking',
      icon: Icons.cloud_done_rounded,
    ),
    SettingsSearchItem(
      title: 'Kitsu',
      subtitle: AppLocalizations.of(context).connectAndManageKitsuCredentials,
      categoryKey: 'tracking',
      icon: Icons.cloud_done_rounded,
    ),
    SettingsSearchItem(
      title: 'Shikimori',
      subtitle: AppLocalizations.of(context).connectAndManageShikimoriToken,
      categoryKey: 'tracking',
      icon: Icons.cloud_done_rounded,
    ),
    SettingsSearchItem(
      title: 'Simkl',
      subtitle: AppLocalizations.of(context).connectAndManageSimklOauth,
      categoryKey: 'tracking',
      icon: Icons.cloud_done_rounded,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).fribbIdMappingDatabase,
      subtitle: AppLocalizations.of(context).crossPlatformAnimeAndMangaIdMapping,
      categoryKey: 'database',
      icon: Icons.storage_rounded,
    ),
    SettingsSearchItem(
      title: AppLocalizations.of(context).aboutMoesync,
      subtitle: AppLocalizations.of(context).versionArchitectureLicenses,
      categoryKey: 'about',
      icon: Icons.info_outline,
    ),
  ];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsList(context);
  }

  Widget _buildResultsList(BuildContext context) {
    final filtered = searchableItems(context).where((item) {
      final q = query.toLowerCase().trim();
      if (q.isEmpty) return true;
      return item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noMatchingSettingsFound));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final cat = settingsCategories(context).firstWhere(
          (c) => c.key == item.categoryKey,
          orElse: () => settingsCategories(context).first,
        );
        return ListTile(
          leading: Icon(
            item.icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(item.title),
          subtitle: Text(item.subtitle),
          onTap: () {
            close(context, null);
            openCategory(cat, context);
          },
        );
      },
    );
  }
}
