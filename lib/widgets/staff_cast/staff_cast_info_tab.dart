import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/screens/staff_cast_details_screen.dart';
import 'package:moesync/widgets/staff_cast/staff_cast_meta_table.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffCastInfoTab extends StatelessWidget {
  const StaffCastInfoTab({
    super.key,
    required this.widget,
    required this._staffData,
    required this._characterData,
    required this.context,
    required this.theme,
    required this.displayName,
    required this.displayImage,
  });

  final StaffCastDetailScreen widget;
  final StaffDetailData? _staffData;
  final CharacterDetailData? _characterData;
  final BuildContext context;
  final ThemeData theme;
  final String displayName;
  final String? displayImage;

  @override
  Widget build(BuildContext context) {
    final nativeName = widget.staffCastType == StaffCastType.staff
        ? (_staffData?.nativeName ?? widget.staffCastName)
        : (_characterData?.nativeName ?? widget.staffCastName);
    final altNames = widget.staffCastType == StaffCastType.staff
        ? (_staffData?.alternativeNames ?? [])
        : (_characterData?.alternativeNames ?? []);
    final desc = widget.staffCastType == StaffCastType.staff
        ? (_staffData?.description ?? '')
        : (_characterData?.description ?? '');
    final links = _staffData?.websiteUrls ?? [];
    final voiceActors = _characterData?.voiceActors ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage:
                    displayImage != null && displayImage!.isNotEmpty
                    ? CachedNetworkImageProvider(displayImage!)
                    : null,
                child: displayImage == null || displayImage!.isEmpty
                    ? const Icon(Icons.person_rounded, size: 46)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (nativeName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        nativeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (altNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        altNames.join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (widget.language != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.language!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          StaffCastMetaTable(
            staffData: _staffData,
            context: context,
            widget: widget,
            characterData: _characterData,
            theme: theme,
          ),
          const SizedBox(height: 20),

          if (links.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: links.map((url) {
                final uri = Uri.tryParse(url);
                final label = url.contains('twitter') || url.contains('x.com')
                    ? 'Twitter'
                    : (url.contains('instagram')
                          ? 'Instagram'
                          : AppLocalizations.of(context).website);

                return ActionChip(
                  avatar: const Icon(Icons.link_rounded, size: 16),
                  label: Text(label),
                  onPressed: () async {
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          if (voiceActors.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context).voiceActors.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: voiceActors.map((va) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () {
                        context.push(
                          '/staffCastDetail',
                          extra: {
                            'staffCastId': va.id,
                            'malId': va.id,
                            'staffCastName': va.name,
                            'imageUrl': va.imageUrl,
                            'staffCastType': StaffCastType.staff,
                            'language': va.language,
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              backgroundImage:
                                  va.imageUrl != null && va.imageUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(va.imageUrl!)
                                  : null,
                              child: va.imageUrl == null
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  va.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  va.language,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (desc.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context).biographyDescription.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
