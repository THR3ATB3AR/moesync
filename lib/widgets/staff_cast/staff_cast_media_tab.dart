import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/providers/providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/models/media_item.dart';
import 'package:go_router/go_router.dart';

class StaffCastMediaTab extends ConsumerStatefulWidget {
  final StaffDetailData staffData;
  final WidgetRef ref;
  final ThemeData theme;
  final String mediaFilter;
  final Function(String) setFilter;

  const StaffCastMediaTab({
    super.key,
    required this.staffData,
    required this.ref,
    required this.theme,
    required this.mediaFilter,
    required this.setFilter,
  });

  @override
  ConsumerState<StaffCastMediaTab> createState() => _StaffCastMediaTabState();
}

class _StaffCastMediaTabState extends ConsumerState<StaffCastMediaTab> {
  @override
  Widget build(BuildContext context) {
    final mediaLibrary = ref.watch(mediaLibraryProvider);
    var roles = widget.staffData.mediaRoles;

    if (widget.mediaFilter == 'on_list') {
      roles = roles.where((r) {
        return mediaLibrary.unifiedItems.any(
          (u) =>
              (r.mediaMalId != null &&
                  r.mediaMalId! > 0 &&
                  u.malId == r.mediaMalId) ||
              (r.mediaId > 0 && u.malId == r.mediaId) ||
              u.title.toLowerCase() == r.mediaTitle.toLowerCase(),
        );
      }).toList();
    } else if (widget.mediaFilter == 'anime') {
      roles = roles.where((r) => r.mediaType == MediaType.anime).toList();
    } else if (widget.mediaFilter == 'manga') {
      roles = roles.where((r) => r.mediaType == MediaType.manga).toList();
    }
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                selected: widget.mediaFilter == 'all',
                label: Text(AppLocalizations.of(context).all),
                onSelected: (_) => widget.setFilter('all'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: widget.mediaFilter == 'on_list',
                label: Text(AppLocalizations.of(context).onMyList),
                onSelected: (_) => widget.setFilter('on_list'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: widget.mediaFilter == 'anime',
                label: Text(AppLocalizations.of(context).anime),
                onSelected: (_) => widget.setFilter('anime'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: widget.mediaFilter == 'manga',
                label: Text(AppLocalizations.of(context).manga),
                onSelected: (_) => widget.setFilter('manga'),
              ),
            ],
          ),
        ),
        Expanded(
          child: roles.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      alignment: Alignment.center,
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).noProductionsForSelectedFilter,
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          color: widget.theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    final item = roles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: widget.theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: widget.theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          final unified = resolveMediaItem(
                            id: item.mediaId,
                            malId: item.mediaMalId,
                            title: item.mediaTitle,
                            posterImage: item.mediaPosterImage,
                            mediaType: item.mediaType,
                            ref: ref,
                          );
                          context.push('/mediaDetails', extra: unified);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 52,
                                  height: 74,
                                  child:
                                      item.mediaPosterImage != null &&
                                          item.mediaPosterImage!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: item.mediaPosterImage!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) =>
                                              const Icon(Icons.movie_rounded),
                                        )
                                      : const Icon(Icons.movie_rounded),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.mediaTitle,
                                      style: widget.theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.role,
                                      style: widget.theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: widget
                                                .theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
