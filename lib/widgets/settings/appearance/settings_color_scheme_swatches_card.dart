import 'package:moesync/providers/providers.dart';
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
    final activePreset = themeColorPresets.firstWhere(
      (p) => p.color.toARGB32() == themeSettings.seedColor.toARGB32(),
      orElse: () => themeColorPresets.first,
    );
    final activeSchemeName = themeSettings.useDynamicColor
        ? 'Dynamic from wallpaper (Material You)'
        : activePreset.name;

    return SettingsCard(
      icon: Icons.palette_outlined,
      title: "Color theme",
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
                    tooltip: 'Dynamic from wallpaper',
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
                  tooltip: preset.name,
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
}
