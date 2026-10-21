import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/app_release.dart';
import '../../providers/providers.dart';
import '../../services/release_service.dart';
import '../../widgets/release_markdown.dart';
import '../../widgets/update_available_dialog.dart';

class ReleaseNotesPage extends ConsumerStatefulWidget {
  const ReleaseNotesPage({super.key});

  @override
  ConsumerState<ReleaseNotesPage> createState() => _ReleaseNotesPageState();
}

class _ReleaseNotesPageState extends ConsumerState<ReleaseNotesPage> {
  late Future<List<AppRelease>> _releases;
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    final service = ref.read(releaseServiceProvider);
    _releases = service.cachedReleases == null
        ? service.fetchReleases()
        : Future.value(service.cachedReleases);
  }

  Future<void> _checkNow() async {
    setState(() => _isChecking = true);
    try {
      final releases = await ref.read(releaseServiceProvider).checkManually();
      if (releases.isNotEmpty) {
        final latestRelease = releases.firstWhere(
          (release) => !release.isPrerelease,
          orElse: () => releases.first,
        );
        final packageInfo = await _packageInfo;
        if (!mounted) return;
        if (ReleaseService.isUpdateAvailable(
          packageInfo.version,
          latestRelease,
        )) {
          await showDialog<void>(
            context: context,
            builder: (context) => UpdateAvailableDialog(
              release: latestRelease,
              currentVersion: packageInfo.version,
            ),
          );
        }
      }
      if (mounted) setState(() => _releases = Future.value(releases));
    } catch (error) {
      if (mounted) {
        setState(() => _releases = Future.error(error));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _openDownload(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final frequency = ref.watch(updateCheckFrequencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.releaseNotesAndUpdates),
        actions: [
          IconButton(
            tooltip: localizations.checkForUpdatesNow,
            onPressed: _isChecking ? null : _checkNow,
            icon: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<AppRelease>>(
        future: _releases,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 40,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.releaseLoadFailed('${snapshot.error}'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _checkNow,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(localizations.checkForUpdatesNow),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final releases = snapshot.data!;
          if (releases.isEmpty) {
            return Center(child: Text(localizations.noReleasesAvailable));
          }

          return FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, packageSnapshot) {
              final currentVersion = packageSnapshot.data?.version;
              final latestRelease = releases.firstWhere(
                (release) => !release.isPrerelease,
                orElse: () => releases.first,
              );
              final updateAvailable =
                  currentVersion != null &&
                  ReleaseService.isUpdateAvailable(
                    currentVersion,
                    latestRelease,
                  );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  DropdownButtonFormField<UpdateCheckFrequency>(
                    initialValue: frequency,
                    decoration: InputDecoration(
                      labelText: localizations.updateCheckFrequency,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: UpdateCheckFrequency.manual,
                        child: Text(localizations.updateCheckManual),
                      ),
                      DropdownMenuItem(
                        value: UpdateCheckFrequency.daily,
                        child: Text(localizations.updateCheckDaily),
                      ),
                      DropdownMenuItem(
                        value: UpdateCheckFrequency.onAppOpen,
                        child: Text(localizations.updateCheckOnAppOpen),
                      ),
                    ],
                    onChanged: (newFrequency) {
                      if (newFrequency != null) {
                        ref
                            .read(updateCheckFrequencyProvider.notifier)
                            .setFrequency(newFrequency);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (currentVersion != null)
                    _VersionSummaryCard(
                      currentVersion: currentVersion,
                      latestVersion: latestRelease.tagName,
                      updateAvailable: updateAvailable,
                    ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < releases.length; index++)
                    _ReleaseCard(
                      release: releases[index],
                      isLatest:
                          releases[index].tagName == latestRelease.tagName,
                      onDownload: _openDownload,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _VersionSummaryCard extends StatelessWidget {
  const _VersionSummaryCard({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
  });

  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return Card(
      color: updateAvailable
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              updateAvailable ? Icons.system_update_alt : Icons.check_circle,
              color: updateAvailable
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.currentVersion}: $currentVersion',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${localizations.latestVersion}: $latestVersion',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    updateAvailable
                        ? localizations.updateAvailable
                        : localizations.appIsUpToDate,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    required this.release,
    required this.isLatest,
    required this.onDownload,
  });

  final AppRelease release;
  final bool isLatest;
  final ValueChanged<Uri> onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final target = ReleaseDownloadTarget.current;
    final asset = target?.selectAsset(release.assets);
    final publishedAt = release.publishedAt;
    final releaseTitle =
        release.name.trim().isEmpty || release.name == release.tagName
        ? release.tagName
        : '${release.name} (${release.tagName})';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: isLatest,
        leading: Icon(
          isLatest ? Icons.new_releases_outlined : Icons.history,
          color: isLatest ? theme.colorScheme.primary : null,
        ),
        title: Text(
          releaseTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: publishedAt == null
            ? null
            : Text(
                localizations.publishedOn(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(publishedAt.toLocal()),
                ),
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (release.isPrerelease)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(localizations.preRelease),
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (release.body.trim().isNotEmpty)
            ReleaseMarkdown(body: release.body),
          if (release.body.trim().isEmpty)
            Text(
              localizations.releaseChangelog,
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: asset == null
                  ? null
                  : () => onDownload(asset.downloadUrl),
              icon: const Icon(Icons.download_rounded),
              label: Text(
                asset == null
                    ? localizations.noDownloadForThisDevice
                    : '${localizations.releaseDownloads} · ${target!.operatingSystem} ${target.architecture}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
