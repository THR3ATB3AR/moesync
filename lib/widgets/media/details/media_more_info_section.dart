import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:flutter/material.dart';

class MediaMoreInfoSection extends StatelessWidget {
  const MediaMoreInfoSection({
    super.key,
    required this.context,
    required this.theme,
    required this.data,
  });

  final BuildContext context;
  final ThemeData theme;
  final MediaDetailData data;

  @override
  Widget build(BuildContext context) {
    final infoRows = <MapEntry<String, String>>[];

    if (data.duration != null) {
      infoRows.add(
        MapEntry(AppLocalizations.of(context).duration, data.duration!),
      );
    }
    if (data.startDate != null) {
      infoRows.add(
        MapEntry(AppLocalizations.of(context).startDate, data.startDate!),
      );
    }
    if (data.endDate != null) {
      infoRows.add(
        MapEntry(AppLocalizations.of(context).endDate, data.endDate!),
      );
    }
    if (data.season != null) {
      infoRows.add(MapEntry(AppLocalizations.of(context).season, data.season!));
    }
    if (data.broadcast != null) {
      infoRows.add(
        MapEntry(AppLocalizations.of(context).broadcast, data.broadcast!),
      );
    }
    if (data.source != null) {
      infoRows.add(MapEntry(AppLocalizations.of(context).source, data.source!));
    }
    if (data.studios.isNotEmpty) {
      infoRows.add(
        MapEntry(AppLocalizations.of(context).studios, data.studios.join(', ')),
      );
    }
    if (data.synonyms.isNotEmpty) {
      infoRows.add(
        MapEntry(
          AppLocalizations.of(context).synonyms,
          data.synonyms.join(', '),
        ),
      );
    }
    if (data.nativeTitle != null && data.nativeTitle!.isNotEmpty) {
      infoRows.add(
        MapEntry(AppLocalizations.of(context).japanese, data.nativeTitle!),
      );
    }
    if (data.romajiTitle != null && data.romajiTitle!.isNotEmpty) {
      infoRows.add(
        MapEntry(AppLocalizations.of(context).roman, data.romajiTitle!),
      );
    }
    if (data.englishTitle != null && data.englishTitle!.isNotEmpty) {
      infoRows.add(
        MapEntry(AppLocalizations.of(context).english, data.englishTitle!),
      );
    }

    if (infoRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaSectionHeader(
            theme: theme,
            title: AppLocalizations.of(context).moreInformation,
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: infoRows.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
