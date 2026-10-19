import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MediaStaffCastCard extends StatefulWidget {
  final MediaCharacterItem? character;
  final MediaStaffItem? staff;
  final ThemeData theme;
  final VoidCallback onPressed;
  final void Function(MediaCharacterItem)? onVoiceActorsPressed;
  final StaffCastType type;

  const MediaStaffCastCard({
    super.key,
    this.character,
    this.staff,
    required this.theme,
    required this.onPressed,
    this.onVoiceActorsPressed,
    required this.type,
  });

  @override
  State<MediaStaffCastCard> createState() => _MediaStaffCastCardState();
}

class _MediaStaffCastCardState extends State<MediaStaffCastCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: widget.theme.colorScheme.surfaceContainerHighest,
            backgroundImage: widget.type == StaffCastType.character
                ? widget.character?.imageUrl != null &&
                          widget.character!.imageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(widget.character!.imageUrl!)
                      : null
                : widget.staff?.imageUrl != null &&
                      widget.staff!.imageUrl!.isNotEmpty
                ? CachedNetworkImageProvider(widget.staff!.imageUrl!)
                : null,
            child: widget.type == StaffCastType.character
                ? widget.character!.imageUrl == null ||
                          widget.character!.imageUrl!.isEmpty
                      ? const Icon(Icons.face_rounded, size: 42)
                      : null
                : widget.staff!.imageUrl == null ||
                      widget.staff!.imageUrl!.isEmpty
                ? const Icon(Icons.face_rounded, size: 42)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.type == StaffCastType.character
                      ? widget.character!.name
                      : widget.staff!.name,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.character?.role ?? widget.staff!.role,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: widget.theme.colorScheme.primary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.type == StaffCastType.character)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.record_voice_over_rounded, size: 26),
                tooltip: AppLocalizations.of(
                  context,
                ).voiceActorsCName(widget.character!.name),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () =>
                    widget.onVoiceActorsPressed!(widget.character!),
              ),
            ),
        ],
      ),
    );
  }
}
