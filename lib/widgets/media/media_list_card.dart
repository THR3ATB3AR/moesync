import 'package:moesync/widgets/media/edit_media_dialog.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/models/media_item.dart';
import 'package:go_router/go_router.dart';

class MediaListCard extends ConsumerStatefulWidget {
  final UnifiedMediaItem item;
  final MediaType type;

  const MediaListCard({super.key, required this.item, required this.type});

  @override
  ConsumerState<MediaListCard> createState() => _MediaListCardState();
}

class _MediaListCardState extends ConsumerState<MediaListCard> {
  @override
  Widget build(BuildContext context) {
    final pendingProgressDelta = ref.watch(
      mediaLibraryProvider.select(
        (state) =>
            state.pendingProgressDeltas[(
              widget.item.mediaType,
              widget.item.malId,
            )] ??
            0,
      ),
    );
    final titleLanguage = ref.watch(languageSettingsProvider).titleLanguage;
    final firstItem = widget.item.services.values.firstOrNull;
    final progress = firstItem?.progress ?? 0;
    final totalProgress = widget.item.resolvedTotalProgress;
    final score = firstItem?.score ?? 0;
    final status =
        firstItem?.status ??
        (widget.type == MediaType.anime ? 'plan_to_watch' : 'plan_to_read');
    final formattedScore = score > 0
        ? (score == score.roundToDouble()
              ? score.toInt().toString()
              : score.toString())
        : '—';

    final double? progressPercent = (totalProgress != null && totalProgress > 0)
        ? (progress / totalProgress).clamp(0.0, 1.0)
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () {
          context.push('/mediaDetails', extra: widget.item);
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (_) => EditMediaDialog(item: widget.item),
          );
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 82,
                          height: 114,
                          child: widget.item.posterImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.item.posterImage,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                )
                              : Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.movie, size: 36),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formattedScore,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.star_rounded,
                                color: score > 0
                                    ? Colors.amber
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 114,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.titleFor(titleLanguage),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(
                                    status,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: getStatusColor(
                                      status,
                                    ).withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  getStatusLabel(status, widget.type, context),
                                  style: TextStyle(
                                    color: getStatusColor(status),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: widget.item.services.keys.map((
                                      s,
                                    ) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4,
                                        ),
                                        child: ServiceBadgeChip(
                                          service: s,
                                          size: 13,
                                          compact: true,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: '$progress'),
                                    if (pendingProgressDelta != 0)
                                      TextSpan(
                                        text: pendingProgressDelta > 0
                                            ? ' (+$pendingProgressDelta)'
                                            : ' ($pendingProgressDelta)',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    TextSpan(
                                      text:
                                          '/${totalProgress != null && totalProgress > 0 ? totalProgress : '-'}',
                                    ),
                                  ],
                                ),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: progress + pendingProgressDelta > 0
                                          ? () => ref
                                                .read(
                                                  mediaLibraryProvider.notifier,
                                                )
                                                .queueProgressChange(
                                                  widget.item,
                                                  -1,
                                                )
                                          : null,
                                      child: Opacity(
                                        opacity:
                                            progress + pendingProgressDelta > 0
                                            ? 1.0
                                            : 0.35,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            '-1',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => ref
                                          .read(mediaLibraryProvider.notifier)
                                          .queueProgressChange(widget.item, 1),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Text(
                                          '+1',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (progressPercent != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 3.5,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
