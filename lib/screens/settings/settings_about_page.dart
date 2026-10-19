import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/settings/about/settings_about_card.dart';
import 'package:flutter/material.dart';

class SettingsAboutPage extends StatelessWidget {
  const SettingsAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).about,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [const SettingsAboutCard()],
      ),
    );
  }
}
