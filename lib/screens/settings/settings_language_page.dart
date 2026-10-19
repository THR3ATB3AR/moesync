import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/settings/settings_card.dart';

class SettingsLanguagePage extends ConsumerWidget {
  const SettingsLanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final languageSettings = ref.watch(languageSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.languageSettings,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          SettingsCard(
            icon: Icons.translate_rounded,
            title: localizations.appLanguage,
            subtitle: localizations.appLanguageDescription,
            content: DropdownButtonFormField<String>(
              key: ValueKey('app_language_${languageSettings.appLanguageCode}'),
              initialValue: languageSettings.appLanguageCode ?? 'system',
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(localizations.useSystemLanguage),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(localizations.englishLanguage),
                ),
                DropdownMenuItem(
                  value: 'pl',
                  child: Text(localizations.polishLanguage),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text(localizations.spanishLanguage),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(languageSettingsProvider.notifier)
                      .setAppLanguage(value == 'system' ? null : value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          SettingsCard(
            icon: Icons.title_rounded,
            title: localizations.titleLanguage,
            subtitle: localizations.titleLanguageDescription,
            content: DropdownButtonFormField<TitleLanguage>(
              key: ValueKey(
                'title_language_${languageSettings.titleLanguage.name}',
              ),
              initialValue: languageSettings.titleLanguage,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: TitleLanguage.source,
                  child: Text(localizations.titleLanguageSource),
                ),
                DropdownMenuItem(
                  value: TitleLanguage.english,
                  child: Text(localizations.titleLanguageEnglish),
                ),
                DropdownMenuItem(
                  value: TitleLanguage.japanese,
                  child: Text(localizations.titleLanguageJapanese),
                ),
                DropdownMenuItem(
                  value: TitleLanguage.romaji,
                  child: Text(localizations.titleLanguageRomaji),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(languageSettingsProvider.notifier)
                      .setTitleLanguage(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
