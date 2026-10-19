import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/widgets/media/edit_media_dialog.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MediaInteractiveMediaCard extends StatelessWidget {
  const MediaInteractiveMediaCard({
    super.key,
    required this.context,
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.posterImage,
    required this.sourceService,
    required this.targetItem,
    required this.isInLibrary,
  });

  final BuildContext context;
  final ThemeData theme;
  final String title;
  final String subtitle;
  final String? posterImage;
  final ServiceType sourceService;
  final UnifiedMediaItem targetItem;
  final bool isInLibrary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              InkWell(
                onTap: () {
                  context.push('/mediaDetails', extra: targetItem);
                },
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 165,
                    child: (posterImage != null && posterImage!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: posterImage!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image, size: 28),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.movie, size: 28),
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: ServiceBadgeChip(service: sourceService, size: 14),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => EditMediaDialog(item: targetItem),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isInLibrary
                            ? Colors.green.shade700
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isInLibrary
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            isInLibrary
                                ? AppLocalizations.of(context).inLibrary
                                : AppLocalizations.of(context).add,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              context.push('/mediaDetails', extra: targetItem);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
