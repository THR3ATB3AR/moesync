import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/services/anime_api_mapping_service.dart';
import 'package:moesync/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsDatabaseCard extends ConsumerStatefulWidget {
  const SettingsDatabaseCard({
    super.key,
    required this.theme,
    required this.animeApi,
  });

  final ThemeData theme;
  final AnimeApiMappingService animeApi;

  @override
  ConsumerState<SettingsDatabaseCard> createState() =>
      _SettingsDatabaseCardState();
}

class _SettingsDatabaseCardState extends ConsumerState<SettingsDatabaseCard> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    widget.animeApi.addListener(_onDatabaseChanged);
    _initializeDatabase();
  }

  @override
  void didUpdateWidget(covariant SettingsDatabaseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animeApi != widget.animeApi) {
      oldWidget.animeApi.removeListener(_onDatabaseChanged);
      widget.animeApi.addListener(_onDatabaseChanged);
    }
  }

  @override
  void dispose() {
    widget.animeApi.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeDatabase() async {
    try {
      await widget.animeApi.initialize();
    } catch (error) {
      debugPrint('Failed to initialize AnimeApi database: $error');
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateDatabase() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    final localizations = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(localizations.downloadingAnimeApiDatabase),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final success = await widget.animeApi.refreshMapping();
    if (!mounted) return;
    setState(() => _isUpdating = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? localizations.successfullyUpdatedMappingDatabase
              : widget.animeApi.isLoaded
              ? localizations.failedToDownloadMappingUsingLocalCache
              : localizations.failedToDownloadMappingNoLocalDatabase,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final metadata = widget.animeApi.metadata;
    final subtitle = <String>[
      widget.animeApi.isLoaded
          ? localizations.animeApiRecordCount(
              metadata?.recordCount ?? widget.animeApi.mappingsCount,
            )
          : localizations.animeApiDatabaseNotDownloaded,
      if (metadata?.sourceUpdatedAt case final sourceUpdatedAt?)
        localizations.animeApiBuiltAt(
          MaterialLocalizations.of(
            context,
          ).formatMediumDate(sourceUpdatedAt.toLocal()),
        ),
      if (metadata != null)
        localizations.animeApiDownloadedAt(
          MaterialLocalizations.of(
            context,
          ).formatMediumDate(metadata.downloadedAt.toLocal()),
        ),
      localizations.animeApiAutoRefreshDaily,
      localizations.animeApiSource,
      localizations.animeApiLicense,
    ].join('\n');

    return SettingsCard(
      title: localizations.animeApiDatabase,
      subtitle: subtitle,
      icon: Icons.storage_rounded,
      content: FilledButton.tonalIcon(
        onPressed: _isUpdating ? null : _updateDatabase,
        icon: _isUpdating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_download_outlined, size: 18),
        label: Text(localizations.updateMappingDatabase),
      ),
    );
  }
}
