import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/widgets/media/details/media_section_header.dart';
import 'package:moesync/widgets/media/details/media_staff_cast_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MediaCharactersAndStaffSection extends StatelessWidget {
  const MediaCharactersAndStaffSection({
    super.key,
    required this.context,
    required this.theme,
    required this.data,
    this.staffOverride,
    this.charactersOverride,
  });

  final BuildContext context;
  final ThemeData theme;
  final MediaDetailData data;
  final List<MediaStaffItem>? staffOverride;
  final List<MediaCharacterItem>? charactersOverride;

  @override
  Widget build(BuildContext context) {
    final staff = staffOverride ?? data.sortedStaff;
    final characters = charactersOverride ?? data.sortedCharacters;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (staff.isNotEmpty) ...[
            MediaSectionHeader(
              theme: theme,
              title: AppLocalizations.of(context).staff,
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: staff.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        context.push(
                          '/staffCastDetail',
                          extra: {
                            'staffCastId': s.id,
                            'malId': s.malId,
                            'staffCastName': s.name,
                            'imageUrl': s.imageUrl,
                            'staffCastType': StaffCastType.staff,
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: MediaStaffCastCard(
                        staff: s,
                        theme: theme,
                        type: StaffCastType.staff,
                        onPressed: () => context.push(
                          '/staffCastDetail',
                          extra: {
                            'staffCastId': s.id,
                            'malId': s.malId,
                            'staffCastName': s.name,
                            'imageUrl': s.imageUrl,
                            'staffCastType': StaffCastType.staff,
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (characters.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MediaSectionHeader(
                  theme: theme,
                  title: AppLocalizations.of(context).characters,
                  icon: Icons.person_2_rounded,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: characters.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            context.push(
                              '/staffCastDetail',
                              extra: {
                                'staffCastId': c.id,
                                'malId': c.malId,
                                'staffCastName': c.name,
                                'imageUrl': c.imageUrl,
                                'staffCastType': StaffCastType.character,
                                'role': c.role,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: MediaStaffCastCard(
                            character: c,
                            theme: theme,
                            onPressed: () => context.push(
                              '/staffCastDetail',
                              extra: {
                                'staffCastId': c.id,
                                'malId': c.malId,
                                'staffCastName': c.name,
                                'imageUrl': c.imageUrl,
                                'staffCastType': StaffCastType.character,
                                'role': c.role,
                              },
                            ),
                            onVoiceActorsPressed: (character) =>
                                _showVoiceActorsSheet(context, character),
                            type: StaffCastType.character,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<dynamic> _showVoiceActorsSheet(
    BuildContext context,
    MediaCharacterItem character,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        final vas = character.sortedVoiceActors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        backgroundImage:
                            character.imageUrl != null &&
                                character.imageUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(character.imageUrl!)
                            : null,
                        child:
                            character.imageUrl == null ||
                                character.imageUrl!.isEmpty
                            ? const Icon(Icons.face_rounded, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).voiceActorsCharacterName(character.name),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (vas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).noVoiceActorInformationAvailableForThisCharacter,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: vas.length,
                      itemBuilder: (ctx, index) {
                        final va = vas[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            backgroundImage:
                                va.imageUrl != null && va.imageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(va.imageUrl!)
                                : null,
                            child: va.imageUrl == null || va.imageUrl!.isEmpty
                                ? const Icon(Icons.person_rounded, size: 22)
                                : null,
                          ),
                          title: Text(
                            va.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            va.language,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onTap: () {
                            Navigator.of(bottomSheetContext).pop();
                            context.push(
                              '/staffCastDetail',
                              extra: {
                                'staffCastId': va.id,
                                'malId': va.id,
                                'staffCastName': va.name,
                                'imageUrl': va.imageUrl,
                                'staffCastType': StaffCastType.staff,
                                'role': va.language,
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
