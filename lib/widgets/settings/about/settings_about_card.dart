import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/screens/settings/release_notes_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsAboutCard extends ConsumerStatefulWidget {
  const SettingsAboutCard({super.key});

  @override
  ConsumerState<SettingsAboutCard> createState() => _SettingsAboutCardState();
}

class _SettingsAboutCardState extends ConsumerState<SettingsAboutCard> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Future<void> _openExternalUrl(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showMessage(AppLocalizations.of(context).couldNotOpenLink);
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(
          AppLocalizations.of(context).couldNotOpenLinkWithError('$error'),
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _platformName {
    return switch (Platform.operatingSystem) {
      'android' => 'Android',
      'windows' => 'Windows',
      'linux' => 'Linux',
      final platform => platform,
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final displayStyle = ref.watch(serviceDisplayStyleProvider);

    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final packageInfo = snapshot.data;
        return Column(
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (displayStyle != ServiceDisplayStyle.text) ...[
                  if (displayStyle == ServiceDisplayStyle.icon)
                    Image.asset(
                      'assets/icon/png/moesync-icon.png',
                      width: 76,
                      height: 76,
                    )
                  else
                    Image.asset(
                      'assets/icon/png/moesync-icon-mono.png',
                      width: 76,
                      height: 76,
                      color: theme.colorScheme.primary,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  const SizedBox(width: 16),
                ],
                Text(
                  'MoeSync',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.aboutMoesyncDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (packageInfo == null && snapshot.hasError)
              Text(
                localizations.versionUnavailable,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                localizations.appVersionPlatform(
                  packageInfo?.version ?? '…',
                  _platformName,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                localizations.appBuildNumber(packageInfo?.buildNumber ?? '…'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            Text(
              localizations.appCreatedBy,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _AboutDivider(theme: theme),
            const SizedBox(height: 16),
            Text(
              localizations.socialLinks,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _AboutSocialButton(
                  label: localizations.github,
                  colorAsset: 'assets/github.svg',
                  monoAsset: 'assets/github-mono.svg',
                  style: displayStyle,
                  onPressed: () => _openExternalUrl(
                    Uri.parse('https://github.com/THR3ATB3AR/moesync'),
                  ),
                ),
                _AboutSocialButton(
                  label: 'Weblate',
                  colorAsset: 'assets/weblate.svg',
                  monoAsset: 'assets/weblate-mono.svg',
                  style: displayStyle,
                  onPressed: () =>
                      _openExternalUrl(Uri.parse('https://weblate.org')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AboutDivider(theme: theme),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'MoeSync',
                  applicationLegalese: localizations.moesyncGplLicense,
                );
              },
              icon: const Icon(Icons.policy_outlined),
              label: Text(localizations.openSourceLicenses),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReleaseNotesPage(),
                ),
              ),
              icon: const Icon(Icons.new_releases_outlined),
              label: Text(localizations.releaseNotesAndUpdates),
            ),
          ],
        );
      },
    );
  }
}

class _AboutSocialButton extends StatelessWidget {
  const _AboutSocialButton({
    required this.label,
    required this.colorAsset,
    required this.monoAsset,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final String colorAsset;
  final String monoAsset;
  final ServiceDisplayStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: label,
      child: Material(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 88,
            height: 78,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (style != ServiceDisplayStyle.text) ...[
                  SvgPicture.asset(
                    style == ServiceDisplayStyle.icon ? colorAsset : monoAsset,
                    width: 26,
                    height: 26,
                    colorFilter: style == ServiceDisplayStyle.monoIcon
                        ? ColorFilter.mode(
                            theme.colorScheme.onSecondaryContainer,
                            BlendMode.srcIn,
                          )
                        : null,
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutDivider extends StatelessWidget {
  const _AboutDivider({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Divider(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
