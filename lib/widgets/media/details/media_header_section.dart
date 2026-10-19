import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/models/media_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MediaHeaderSection extends StatelessWidget {
  const MediaHeaderSection({
    super.key,
    required this.context,
    required this.theme,
    required this.liveItem,
    required this.data,
    required this.titleLanguage,
  });

  final BuildContext context;
  final ThemeData theme;
  final UnifiedMediaItem liveItem;
  final MediaDetailData data;
  final TitleLanguage titleLanguage;

  @override
  Widget build(BuildContext context) {
    final isAnime = liveItem.mediaType == MediaType.anime;
    final posterUrl = data.posterImage.isNotEmpty
        ? data.posterImage
        : liveItem.posterImage;

    final episodesOrChapters = isAnime
        ? (data.episodes != null
              ? AppLocalizations.of(
                  context,
                ).dataEpisodesEpisodes(data.episodes!)
              : AppLocalizations.of(context).inProgress)
        : (data.chapters != null
              ? AppLocalizations.of(
                  context,
                ).dataChaptersChapters(data.chapters!)
              : (data.volumes != null
                    ? AppLocalizations.of(
                        context,
                      ).dataVolumesVolumes(data.volumes!)
                    : AppLocalizations.of(context).inProgress));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 125,
              height: 180,
              child: posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image, size: 36),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        isAnime
                            ? Icons.movie_filter_rounded
                            : Icons.menu_book_rounded,
                        size: 40,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.titleFor(titleLanguage),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(
                      isAnime ? Icons.movie_outlined : Icons.menu_book_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data.format ?? (isAnime ? AppLocalizations.of(context).tv.toUpperCase() : AppLocalizations.of(context).manga.toUpperCase())}${data.year != null ? " · ${data.year}" : ""}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (data.status != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.sensors_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.status!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                Row(
                  children: [
                    Icon(
                      isAnime ? Icons.timer_outlined : Icons.bookmark_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      episodesOrChapters,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (data.score != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.score!.toStringAsFixed(2),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
