import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/settings/settings_search_delegate.dart';

class SettingsCategoryItem {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const SettingsCategoryItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

List<SettingsCategoryItem> settingsCategories(BuildContext context) {
  return [
    SettingsCategoryItem(
      key: 'language',
      title: AppLocalizations.of(context).languageSettings,
      subtitle: AppLocalizations.of(context).languageSettingsDescription,
      icon: Icons.translate_rounded,
    ),
    SettingsCategoryItem(
      key: 'appearance',
      title: AppLocalizations.of(context).appearance,
      subtitle: AppLocalizations.of(
        context,
      ).themeDisplayModeBadgeStyleLivePreview,
      icon: Icons.palette_outlined,
    ),
    SettingsCategoryItem(
      key: 'sources',
      title: AppLocalizations.of(context).dataSourcesSync,
      subtitle: AppLocalizations.of(
        context,
      ).defaultInformationDescriptionSyncSourceForAnimeManga,
      icon: Icons.hub_outlined,
    ),
    SettingsCategoryItem(
      key: 'tracking',
      title: AppLocalizations.of(context).trackingAccounts,
      subtitle: AppLocalizations.of(
        context,
      ).myanimelistAnilistKitsuShikimoriSimkl,
      icon: Icons.sync_rounded,
    ),
    SettingsCategoryItem(
      key: 'about',
      title: AppLocalizations.of(context).about,
      subtitle: AppLocalizations.of(context).moesyncInfo,
      icon: Icons.info_outline,
    ),
  ];
}

class SettingsScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const SettingsScreen({super.key, this.initialCategory});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

void openCategory(SettingsCategoryItem category, BuildContext context) {
  context.push('/more/settings/${category.key}');
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null &&
        widget.initialCategory!.isNotEmpty &&
        widget.initialCategory != 'all') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openCategoryByKey(widget.initialCategory!);
        }
      });
    }
  }

  void _openCategoryByKey(String key) {
    final normalizedKey = key == 'accounts'
        ? 'tracking'
        : (key == 'storage' ? 'database' : key);
    final cat = settingsCategories(context).firstWhere(
      (c) => c.key == normalizedKey,
      orElse: () => settingsCategories(context).first,
    );
    openCategory(cat, context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppLocalizations.of(context).back,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/more');
            }
          },
        ),
        title: Text(
          AppLocalizations.of(context).settings,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: AppLocalizations.of(context).searchSettings,
            onPressed: () {
              showSearch(context: context, delegate: SettingsSearchDelegate());
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: settingsCategories(context).length,
        itemBuilder: (context, index) {
          final cat = settingsCategories(context)[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            leading: Icon(cat.icon, size: 26, color: theme.colorScheme.primary),
            title: Text(
              cat.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                cat.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            onTap: () => openCategory(cat, context),
          );
        },
      ),
    );
  }
}

class SettingsSearchItem {
  final String title;
  final String subtitle;
  final String categoryKey;
  final IconData icon;

  const SettingsSearchItem({
    required this.title,
    required this.subtitle,
    required this.categoryKey,
    required this.icon,
  });
}
