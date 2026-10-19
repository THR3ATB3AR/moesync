import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/settings/settings_section_title.dart';
import 'package:moesync/widgets/settings/sources_n_database/settings_data_source_card.dart';
import 'package:moesync/widgets/settings/sources_n_database/settings_database_card.dart';
import 'package:moesync/widgets/settings/sources_n_database/settings_manga_database_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsSourcesDatabasePage extends ConsumerWidget {
  const SettingsSourcesDatabasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fribb = ref.watch(fribbServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).sourcesDatabase,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          SettingsSectionTitle(
            theme: theme,
            title: AppLocalizations.of(context).animeDataSourcesSynchronization,
          ),
          const SizedBox(height: 8),
          SettingsDataSourceCard(
            context: context,
            ref: ref,
            theme: theme,
            type: MediaType.anime,
          ),
          const SizedBox(height: 24),
          SettingsSectionTitle(
            theme: theme,
            title: AppLocalizations.of(context).mangaDataSourcesSynchronization,
          ),
          const SizedBox(height: 8),
          SettingsDataSourceCard(
            context: context,
            ref: ref,
            theme: theme,
            type: MediaType.manga,
          ),
          const SizedBox(height: 24),
          SettingsSectionTitle(
            theme: theme,
            title: AppLocalizations.of(context).databaseIdMapping,
          ),
          const SizedBox(height: 8),
          SettingsDatabaseCard(
            context: context,
            ref: ref,
            theme: theme,
            fribb: fribb,
          ),
          const SizedBox(height: 12),
          SettingsMangaDatabaseCard(context: context, ref: ref, theme: theme),
        ],
      ),
    );
  }
}
