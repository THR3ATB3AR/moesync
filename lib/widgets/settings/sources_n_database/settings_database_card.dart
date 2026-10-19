import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/services/fribb_mapping_service.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsDatabaseCard extends StatelessWidget {
  const SettingsDatabaseCard({
    super.key,
    required this.context,
    required this.ref,
    required this.theme,
    required this.fribb,
  });

  final BuildContext context;
  final WidgetRef ref;
  final ThemeData theme;
  final FribbMappingService fribb;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: AppLocalizations.of(context).fribbCrossPlatformDatabase,
      subtitle: fribb.isLoaded
          ? AppLocalizations.of(
              context,
            ).countCrossReferencedAnimeTitlesIndexed(fribb.mappingsCount)
          : AppLocalizations.of(context).cacheLoadedAutoRefreshedDaily,
      icon: Icons.storage_rounded,
      content: FilledButton.tonalIcon(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).downloadingLatestFribbMapping,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          final success = await fribb.refreshMapping();
          if (!context.mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? AppLocalizations.of(
                        context,
                      ).successfullyUpdatedMappingDatabase
                    : AppLocalizations.of(
                        context,
                      ).failedToDownloadMappingUsingLocalCache,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.cloud_download_outlined, size: 18),
        label: Text(AppLocalizations.of(context).updateMappingDatabase),
      ),
    );
  }
}
