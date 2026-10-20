import 'package:moesync/providers/providers.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/theme.dart';
import 'package:moesync/widgets/settings/appearance/settings_swatch_item.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsColorSchemeSwatchesCard extends StatelessWidget {
  const SettingsColorSchemeSwatchesCard({
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
    final activePreset = themeColorPresets.firstWhere(
      (p) => p.color.toARGB32() == themeSettings.seedColor.toARGB32(),
      orElse: () => themeColorPresets.first,
    );
    final activeSchemeName = themeSettings.useDynamicColor
        ? l.dynamicFromWallpaperMaterialYou
        : _localizedPresetName(l, activePreset.name);

    return SettingsCard(
      icon: Icons.palette_outlined,
      title: l.colorTheme,
      subtitle: activeSchemeName,
      content: DynamicColorBuilder(
        builder: (dynamicLight, dynamicDark) {
          return SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 1 + themeColorPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = themeSettings.useDynamicColor;
                  final p = dynamicLight?.primary ?? theme.colorScheme.primary;
                  final s =
                      dynamicLight?.secondary ?? theme.colorScheme.secondary;
                  final t =
                      dynamicLight?.tertiary ?? theme.colorScheme.tertiary;
                  final surf =
                      dynamicLight?.surfaceContainerHighest ??
                      theme.colorScheme.surfaceContainerHighest;

                  return SettingsSwatchItem(
                    context: context,
                    isSelected: isSelected,
                    tooltip: l.dynamicFromWallpaper,
                    colors: [p, s, t, surf],
                    centerIcon: Icons.wallpaper_rounded,
                    onTap: () {
                      ref
                          .read(themeSettingsProvider.notifier)
                          .setUseDynamicColor(true);
                    },
                  );
                }

                final preset = themeColorPresets[index - 1];
                final isSelected =
                    !themeSettings.useDynamicColor &&
                    themeSettings.seedColor.toARGB32() ==
                        preset.color.toARGB32();

                final cs = ColorScheme.fromSeed(
                  seedColor: preset.color,
                  brightness: Brightness.light,
                  dynamicSchemeVariant: themeSettings.schemeVariant,
                );

                return SettingsSwatchItem(
                  context: context,
                  isSelected: isSelected,
                  tooltip: _localizedPresetName(l, preset.name),
                  colors: [
                    cs.primary,
                    cs.secondary,
                    cs.tertiary,
                    cs.surfaceContainerHighest,
                  ],
                  onTap: () {
                    ref
                        .read(themeSettingsProvider.notifier)
                        .setSeedColor(preset.color);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _localizedPresetName(AppLocalizations l, String presetName) =>
      switch (presetName) {
        'Purple (M3)' => l.colorPurpleM3,
        'Indigo' => l.colorIndigo,
        'Blue' => l.colorBlue,
        'Cyan' => l.colorCyan,
        'Teal' => l.colorTeal,
        'Green' => l.colorGreen,
        'Lime' => l.colorLime,
        'Amber' => l.colorAmber,
        'Orange' => l.colorOrange,
        'Deep Orange' => l.colorDeepOrange,
        'Red' => l.colorRed,
        'Pink' => l.colorPink,
        'Sakura Rose' => l.colorSakuraRose,
        'Deep Purple' => l.colorDeepPurple,
        'Blue Grey' => l.colorBlueGrey,
        'Brown' => l.colorBrown,
        _ => presetName,
      };
}
