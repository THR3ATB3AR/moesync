import 'package:moesync/providers/providers.dart';
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

    return SettingsCard(
      icon: Icons.brightness_6_outlined,
      title: "Theme mode",
      subtitle: 'Light, dark or system',
      content: SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_rounded, size: 16),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded, size: 16),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded, size: 16),
              label: Text('Dark'),
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
