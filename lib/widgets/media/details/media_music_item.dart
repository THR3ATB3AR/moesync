import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_detail_data.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaMusicItem extends ConsumerWidget {
  MediaMusicItem({super.key, required this.theme, required this.themeMusic});

  final ThemeData theme;
  final ThemeItem themeMusic;

  final List<MusicService> musicServices = [
    MusicService.spotify,
    MusicService.appleMusic,
    MusicService.youtubeMusic,
  ];

  String _cleanMusicName(String input) {
    String cleaned = input;
    cleaned = cleaned.replaceAll(RegExp(r'^#\d+:\s*'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'\s*\(eps\s*[\d\-]+\)$', caseSensitive: false),
      '',
    );

    return cleaned.trim();
  }

  Future<void> _launchMusicService(
    BuildContext context,
    String musicName,
    MusicService service,
  ) async {
    String cleanedMusicName = _cleanMusicName(musicName);
    String url = '';
    String webUrl = '';
    switch (service) {
      case MusicService.spotify:
        url = 'spotify:search:${Uri.encodeComponent(cleanedMusicName)}';
        webUrl =
            'https://open.spotify.com/search/${Uri.encodeComponent(cleanedMusicName)}';
        break;
      case MusicService.appleMusic:
        url =
            'https://music.apple.com/us/search?term=${Uri.encodeComponent(cleanedMusicName)}';
        webUrl =
            'https://music.apple.com/us/search?term=${Uri.encodeComponent(cleanedMusicName)}';
        break;
      case MusicService.youtubeMusic:
        url =
            'youtubemusic://search?q=${Uri.encodeComponent(cleanedMusicName)}';
        webUrl =
            'https://music.youtube.com/search?q=${Uri.encodeComponent(cleanedMusicName)}';
        break;
    }
    try {
      bool launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  void _showMusicServicesSheet(
    BuildContext context,
    ThemeItem themeMusic,
    ServiceDisplayStyle displayStyle,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
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
                        child: const Icon(Icons.music_note_rounded, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          themeMusic.text,
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
                if (musicServices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).noMusicServicesFound,
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
                      itemCount: musicServices.length,
                      itemBuilder: (ctx, index) {
                        final service = musicServices[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child:
                                  displayStyle == ServiceDisplayStyle.monoIcon
                                  ? SvgPicture.asset(
                                      service.monoIconAsset,
                                      colorFilter: ColorFilter.mode(
                                        theme.colorScheme.primary,
                                        BlendMode.srcIn,
                                      ),
                                    )
                                  : SvgPicture.asset(service.iconAsset),
                            ),
                          ),
                          title: Text(
                            service.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.of(bottomSheetContext).pop();
                            _launchMusicService(
                              context,
                              themeMusic.text,
                              service,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayStyle = ref.watch(serviceDisplayStyleProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextButton.icon(
        icon: const Icon(Icons.music_note_rounded),
        onPressed: () =>
            _showMusicServicesSheet(context, themeMusic, displayStyle),
        label: Text(
          themeMusic.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
