import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/providers/providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:go_router/go_router.dart';

class StaffCastCharactersTab extends ConsumerStatefulWidget {
  final StaffDetailData staffData;
  final String characterFilter;
  final ThemeData theme;
  final WidgetRef ref;
  final void Function(String) setCharacterFilter;

  const StaffCastCharactersTab({
    super.key,
    required this.staffData,
    required this.characterFilter,
    required this.theme,
    required this.ref,
    required this.setCharacterFilter,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StaffCastCharactersTabState();
}

class _StaffCastCharactersTabState
    extends ConsumerState<StaffCastCharactersTab> {
  @override
  Widget build(BuildContext context) {
    final mediaLibrary = widget.ref.watch(mediaLibraryProvider);
    var chars = widget.staffData.characterRoles;

    if (widget.characterFilter == 'on_list') {
      chars = chars.where((c) {
        return mediaLibrary.unifiedItems.any(
          (u) =>
              (c.mediaMalId != null &&
                  c.mediaMalId! > 0 &&
                  u.malId == c.mediaMalId) ||
              (c.mediaId > 0 && u.malId == c.mediaId) ||
              u.title.toLowerCase() == c.mediaTitle.toLowerCase(),
        );
      }).toList();
    }

    chars = stableSort(chars, (a, b) {
      final prioA = getCharacterRolePriority(a.role ?? '');
      final prioB = getCharacterRolePriority(b.role ?? '');
      return prioA.compareTo(prioB);
    });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                selected: widget.characterFilter == 'all',
                label: Text(AppLocalizations.of(context).all),
                onSelected: (_) => widget.setCharacterFilter('all'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: widget.characterFilter == 'on_list',
                label: Text(AppLocalizations.of(context).onMyList),
                onSelected: (_) => widget.setCharacterFilter('on_list'),
              ),
            ],
          ),
        ),
        Expanded(
          child: chars.isEmpty
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
                        ).noCharactersForSelectedFilter,
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
                  itemCount: chars.length,
                  itemBuilder: (context, index) {
                    final item = chars[index];
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
                          context.push(
                            '/staffCastDetail',
                            extra: {
                              'staffCastId': item.characterId,
                              'malId': item.characterMalId,
                              'staffCastName': item.characterName,
                              'imageUrl': item.characterImageUrl,
                              'staffCastType': StaffCastType.character,
                              'role': item.role,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: widget
                                    .theme
                                    .colorScheme
                                    .surfaceContainerHighest,
                                backgroundImage:
                                    item.characterImageUrl != null &&
                                        item.characterImageUrl!.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        item.characterImageUrl!,
                                      )
                                    : null,
                                child: item.characterImageUrl == null
                                    ? const Icon(Icons.face_rounded, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.characterName,
                                      style: widget.theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.mediaTitle,
                                      style: widget.theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: widget
                                                .theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      maxLines: 1,
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
