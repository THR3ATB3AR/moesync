import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsMangaDatabaseCard extends StatelessWidget {
  const SettingsMangaDatabaseCard({
    super.key,
    required this.context,
    required this.ref,
    required this.theme,
  });

  final BuildContext context;
  final WidgetRef ref;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final mangaMapping = ref.watch(mangaMappingServiceProvider);

    return SettingsCard(
      title: AppLocalizations.of(context).cattleDatabase,
      subtitle: AppLocalizations.of(context)
          .countCrossReferencedMangaTitlesCachedMalMangaupdatesAnilistKitsu(
            mangaMapping.mappingsCount,
          ),
      icon: Icons.menu_book_rounded,
    );
  }
}
