import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/media/details/media_interactive_media_card.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaRelationsAndRecommendationsSection extends ConsumerStatefulWidget {
  final MediaDetailData data;
  final Map<ServiceType, MediaDetailData> allServiceData;
  final ServiceType selectedService;
  final ThemeData theme;

  const MediaRelationsAndRecommendationsSection({
    super.key,
    required this.data,
    required this.allServiceData,
    required this.selectedService,
    required this.theme,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MediaRelationsAndRecommendationsSectionState();
}

class _MediaRelationsAndRecommendationsSectionState
    extends ConsumerState<MediaRelationsAndRecommendationsSection> {
  @override
  Widget build(BuildContext context) {
    final library = ref.watch(mediaLibraryProvider);

    final allRelations = <MediaRelationItem>[];
    final seenRelTitles = <String>{};
    for (final r in widget.data.relations) {
      if (seenRelTitles.add(r.title.toLowerCase())) {
        allRelations.add(r);
      }
    }
    for (final other in widget.allServiceData.values) {
      for (final r in other.relations) {
        if (seenRelTitles.add(r.title.toLowerCase())) {
          allRelations.add(r);
        }
      }
    }

    final allRecs = <MediaRecommendationItem>[];
    final seenRecTitles = <String>{};
    for (final r in widget.data.recommendations) {
      if (seenRecTitles.add(r.title.toLowerCase())) {
        allRecs.add(r);
      }
    }
    for (final other in widget.allServiceData.values) {
      for (final r in other.recommendations) {
        if (seenRecTitles.add(r.title.toLowerCase())) {
          allRecs.add(r);
        }
      }
    }

    if (allRelations.isEmpty && allRecs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allRelations.isNotEmpty) ...[
            MediaSectionHeader(
              theme: widget.theme,
              title: AppLocalizations.of(
                context,
              ).relatedCount(allRelations.length),
              icon: Icons.link_rounded,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allRelations.map((rel) {
                  final targetItem = resolveUnifiedItem(
                    id: rel.id,
                    malId: rel.malId,
                    title: rel.title,
                    posterImage: rel.posterImage,
                    mediaType: rel.mediaType,
                    sourceService: rel.sourceService,
                    ref: ref,
                  );

                  final isInLibrary = library.unifiedItems.any(
                    (u) =>
                        (targetItem.malId > 0 && u.malId == targetItem.malId) ||
                        u.title.toLowerCase() == targetItem.title.toLowerCase(),
                  );

                  return MediaInteractiveMediaCard(
                    context: context,
                    theme: widget.theme,
                    title: rel.title,
                    subtitle: rel.relationType,
                    posterImage: rel.posterImage,
                    sourceService: rel.sourceService,
                    targetItem: targetItem,
                    isInLibrary: isInLibrary,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (allRecs.isNotEmpty) ...[
            MediaSectionHeader(
              theme: widget.theme,
              title: AppLocalizations.of(
                context,
              ).recommendationsCount(allRecs.length),
              icon: Icons.recommend_rounded,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allRecs.map((rec) {
                  final targetItem = resolveUnifiedItem(
                    id: rec.id,
                    malId: rec.malId,
                    title: rec.title,
                    posterImage: rec.posterImage,
                    mediaType: rec.mediaType,
                    sourceService: rec.sourceService,
                    ref: ref,
                  );

                  final isInLibrary = library.unifiedItems.any(
                    (u) =>
                        (targetItem.malId > 0 && u.malId == targetItem.malId) ||
                        u.title.toLowerCase() == targetItem.title.toLowerCase(),
                  );

                  return MediaInteractiveMediaCard(
                    context: context,
                    theme: widget.theme,
                    title: rec.title,
                    subtitle: AppLocalizations.of(context).recommended,
                    posterImage: rec.posterImage,
                    sourceService: rec.sourceService,
                    targetItem: targetItem,
                    isInLibrary: isInLibrary,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
