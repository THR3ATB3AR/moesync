import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/media/edit_media_dialog.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MediaGridCard extends ConsumerStatefulWidget {
  final UnifiedMediaItem item;
  final MediaType type;
  const MediaGridCard({super.key, required this.item, required this.type});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MediaGridCardState();
}

class _MediaGridCardState extends ConsumerState<MediaGridCard> {
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

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.item.posterImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.item.posterImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
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
                          child: const Icon(Icons.movie, size: 40),
                        ),
                  if (score > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        getStatusLabel(status, widget.type, context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.titleFor(titleLanguage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text.rich(
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
                                    ' / ${totalProgress != null && totalProgress > 0 ? totalProgress : '-'}',
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (progress + pendingProgressDelta > 0) ...[
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 26,
                                minHeight: 26,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => ref
                                  .read(mediaLibraryProvider.notifier)
                                  .queueProgressChange(widget.item, -1),
                              icon: const Icon(Icons.remove, size: 14),
                            ),
                            const SizedBox(width: 4),
                          ],
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            onPressed: () => ref
                                .read(mediaLibraryProvider.notifier)
                                .queueProgressChange(widget.item, 1),
                            icon: const Icon(Icons.add, size: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: widget.item.services.keys.map((s) {
                      return ServiceBadgeChip(
                        service: s,
                        size: 13,
                        compact: true,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
