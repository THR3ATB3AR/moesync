import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StaffCastMediaCharacterAppearancesTab extends StatelessWidget {
  const StaffCastMediaCharacterAppearancesTab({
    super.key,
    required this._characterData,
    required this.ref,
    required this.theme,
  });

  final CharacterDetailData? _characterData;
  final WidgetRef ref;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final appearances = _characterData?.mediaAppearances ?? [];
    if (appearances.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            alignment: Alignment.center,
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Text(
              AppLocalizations.of(context).noRelatedProductions,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: appearances.length,
      itemBuilder: (context, index) {
        final item = appearances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.role,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
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
    );
  }
}
