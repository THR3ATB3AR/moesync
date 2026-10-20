import 'package:moesync/providers/providers.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsThemeModeCard extends StatelessWidget {
  const SettingsThemeModeCard({
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
    final themeSettings = ref.watch(themeSettingsProvider);
    final l = AppLocalizations.of(context);

    return SettingsCard(
      icon: Icons.brightness_6_outlined,
      title: l.themeMode,
      subtitle: l.themeModeDescription,
      content: SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_rounded, size: 16),
              label: Text(l.themeModeSystem),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded, size: 16),
              label: Text(l.themeModeLight),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded, size: 16),
              label: Text(l.themeModeDark),
            ),
          ],
          selected: {themeSettings.themeMode},
          onSelectionChanged: (set) {
            if (set.isNotEmpty) {
              ref.read(themeSettingsProvider.notifier).setThemeMode(set.first);
            }
          },
        ),
      ),
    );
  }
}
