import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/widgets/media/details/media_music_item.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:flutter/material.dart';

class MediaMusicThemesSection extends StatelessWidget {
  const MediaMusicThemesSection({
    super.key,
    required this.context,
    required this.theme,
    required this.data,
    this.openingThemesOverride,
    this.endingThemesOverride,
  });

  final BuildContext context;
  final ThemeData theme;
  final MediaDetailData data;
  final List<ThemeItem>? openingThemesOverride;
  final List<ThemeItem>? endingThemesOverride;

  @override
  Widget build(BuildContext context) {
    final openingThemes = openingThemesOverride ?? data.openingThemes;
    final endingThemes = endingThemesOverride ?? data.endingThemes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (openingThemes.isNotEmpty) ...[
            MediaSectionHeader(
              theme: theme,
              title: AppLocalizations.of(context).openingThemes,
              icon: Icons.music_video,
            ),
            const SizedBox(height: 8),
            ...openingThemes.map(
              (op) => MediaMusicItem(theme: theme, themeMusic: op),
            ),
            const SizedBox(height: 16),
          ],
          if (endingThemes.isNotEmpty) ...[
            MediaSectionHeader(
              theme: theme,
              title: AppLocalizations.of(context).endingThemes,
              icon: Icons.music_video,
            ),
            const SizedBox(height: 8),
            ...endingThemes.map(
              (ed) => MediaMusicItem(theme: theme, themeMusic: ed),
            ),
          ],
        ],
      ),
    );
  }
}
