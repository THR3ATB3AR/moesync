import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/app_release.dart';
import 'release_markdown.dart';

class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({
    required this.release,
    required this.currentVersion,
    super.key,
  });

  final AppRelease release;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final target = ReleaseDownloadTarget.current;
    final asset = target?.selectAsset(release.assets);
    final downloadUrl = asset?.downloadUrl ?? release.htmlUrl;

    return AlertDialog(
      title: Text(localizations.updateAvailable),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${localizations.currentVersion}: $currentVersion'),
                Text(
                  '${localizations.latestVersion}: ${release.tagName}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.releaseChangelog,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                if (release.body.trim().isEmpty)
                  Text(localizations.noReleaseChangelog)
                else
                  ReleaseMarkdown(body: release.body),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.updateLater),
        ),
        FilledButton.icon(
          onPressed: () => _openDownload(context, downloadUrl),
          icon: const Icon(Icons.download_rounded),
          label: Text(localizations.releaseDownloads),
        ),
      ],
    );
  }

  Future<void> _openDownload(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened && context.mounted) {
        Navigator.of(context).pop();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotOpenLink),
          ),
        );
      }
    } on PlatformException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).couldNotOpenLinkWithError('$error'),
            ),
          ),
        );
      }
    }
  }
}
