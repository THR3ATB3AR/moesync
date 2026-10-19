import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/settings/appearance/settings_color_scheme_swatches_card.dart';
import 'package:moesync/widgets/settings/appearance/settings_display_style_card.dart';
import 'package:moesync/widgets/settings/appearance/settings_dynamic_scheme_variant_card.dart';
import 'package:moesync/widgets/settings/appearance/settings_media_view_mode_card.dart';
import 'package:moesync/widgets/settings/appearance/settings_section_title.dart';
import 'package:moesync/widgets/settings/settings_section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsAppearancePage extends ConsumerWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).appearance,
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
            title: AppLocalizations.of(context).themeMode,
          ),
          const SizedBox(height: 8),
          SettingsThemeModeCard(context: context, ref: ref, theme: theme),
          const SizedBox(height: 20),
          SettingsSectionTitle(
            theme: theme,
            title: AppLocalizations.of(context).colorTheme,
          ),
          const SizedBox(height: 8),
          SettingsColorSchemeSwatchesCard(
            context: context,
            ref: ref,
            theme: theme,
          ),
          const SizedBox(height: 20),
          SettingsSectionTitle(
            theme: theme,
            title: AppLocalizations.of(context).m3Variant,
          ),
          const SizedBox(height: 8),
          SettingsDynamicSchemeVariantCard(
            context: context,
            ref: ref,
            theme: theme,
          ),
          const SizedBox(height: 24),
          SettingsSectionTitle(
            theme: theme,
            title: AppLocalizations.of(context).displayBadges,
          ),
          const SizedBox(height: 8),
          SettingsMediaViewModeCard(context: context, ref: ref, theme: theme),
          const SizedBox(height: 12),
          SettingsDisplayStyleCard(context: context, ref: ref, theme: theme),
        ],
      ),
    );
  }
}
