import 'package:moesync/models/media_item.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/media/edit_media_dialog.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeHorizontalMediaList extends StatelessWidget {
  const HomeHorizontalMediaList({
    super.key,
    required this.context,
    required this.ref,
    required this.items,
    required this.theme,
  });

  final BuildContext context;
  final WidgetRef ref;
  final List<UnifiedMediaItem> items;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titleLanguage = ref.watch(languageSettingsProvider).titleLanguage;
    return SizedBox(
      height: 245,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final firstServiceItem = item.services.values.firstOrNull;
          final progress = firstServiceItem?.progress ?? 0;
          final score = firstServiceItem?.score ?? 0;

          return SizedBox(
            width: 130,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                context.push('/mediaDetails', extra: item);
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (_) => EditMediaDialog(item: item),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.posterImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.posterImage,
                                width: 130,
                                height: 155,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.broken_image),
                                ),
                              )
                            : Container(
                                width: 130,
                                height: 155,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.movie),
                              ),
                      ),
                      if (score > 0)
                        Positioned(
                          top: 6,
                          right: 6,
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
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${l.episodesShort} $progress',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.titleFor(titleLanguage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 46),
                    child: Wrap(
                      spacing: 3,
                      runSpacing: 2,
                      clipBehavior: Clip.hardEdge,
                      children: item.services.keys.map((s) {
                        return ServiceBadgeChip(
                          service: s,
                          size: 11,
                          compact: true,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
