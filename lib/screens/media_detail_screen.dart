import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/media/details/media_characters_and_staff_section.dart';
import 'package:moesync/widgets/media/details/media_description_section.dart';
import 'package:moesync/widgets/media/details/media_genres_row.dart';
import 'package:moesync/widgets/media/details/media_header_section.dart';
import 'package:moesync/widgets/media/details/media_more_info_section.dart';
import 'package:moesync/widgets/media/details/media_multi_service_scores_bar.dart';
import 'package:moesync/widgets/media/details/media_music_themes_section.dart';
import 'package:moesync/widgets/media/details/media_rankings_and_distribution_section.dart';
import 'package:moesync/widgets/media/details/media_relations_and_recommendations_section.dart';
import 'package:moesync/widgets/media/details/media_stats_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/media_detail_data.dart';
import '../models/media_item.dart';
import '../providers/providers.dart';
import '../widgets/media/edit_media_dialog.dart';
import '../widgets/service_badge.dart';
import '../widgets/skeleton_loader.dart';

class MediaDetailScreen extends ConsumerStatefulWidget {
  final UnifiedMediaItem item;

  const MediaDetailScreen({super.key, required this.item});

  @override
  ConsumerState<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends ConsumerState<MediaDetailScreen> {
  late ServiceType _selectedService;
  MediaDetailData? _detailData;
  Map<ServiceType, MediaDetailData> _allServiceData = {};
  bool _isLoading = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();
  final GlobalControllerKeys _sectionKeys = GlobalControllerKeys();

  @override
  void initState() {
    super.initState();

    final supported = _getSupportedServices();
    final defaultInfo = ref
        .read(storageServiceProvider)
        .getDefaultInfoSource(widget.item.mediaType);
    if (supported.contains(defaultInfo)) {
      _selectedService = defaultInfo;
    } else if (supported.contains(ServiceType.mal)) {
      _selectedService = ServiceType.mal;
    } else if (widget.item.services.isNotEmpty) {
      _selectedService = widget.item.services.keys.first;
    } else {
      _selectedService = supported.first;
    }

    _loadDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  UnifiedMediaItem _getLiveItem() {
    final library = ref.watch(mediaLibraryProvider);
    final match = library.unifiedItems.firstWhere(
      (u) =>
          u.malId == widget.item.malId && u.mediaType == widget.item.mediaType,
      orElse: () => widget.item,
    );
    return match;
  }

  List<ServiceType> _getSupportedServices() {
    return ServiceType.forMediaType(widget.item.mediaType);
  }

  Future<void> _loadDetails({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final detailService = ref.read(mediaDetailServiceProvider);
    final currentItem = _getLiveItem();
    final supported = _getSupportedServices();

    try {
      final allData = await detailService.fetchAllServices(
        item: currentItem,
        services: supported,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _allServiceData = allData;
          _detailData =
              _allServiceData[_selectedService] ??
              (_allServiceData.isNotEmpty
                  ? _allServiceData.values.first
                  : null);
          if (_detailData != null &&
              _allServiceData.containsKey(_selectedService)) {
          } else if (_allServiceData.isNotEmpty) {
            _selectedService = _allServiceData.keys.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSelectService(ServiceType service) {
    if (_selectedService == service) return;
    setState(() {
      _selectedService = service;
      if (_allServiceData.containsKey(service)) {
        _detailData = _allServiceData[service];
      }
    });

    if (!_allServiceData.containsKey(service)) {
      _fetchSingleService(service);
    }
  }

  Future<void> _fetchSingleService(
    ServiceType service, {
    bool forceRefresh = false,
  }) async {
    final detailService = ref.read(mediaDetailServiceProvider);
    final currentItem = _getLiveItem();
    final serviceItem = currentItem.services[service];
    final serviceId = serviceItem?.id;

    try {
      final data = await detailService.fetchDetails(
        service: service,
        serviceId: serviceId,
        malId: currentItem.malId,
        title: currentItem.title,
        mediaType: currentItem.mediaType,
        forceRefresh: forceRefresh,
      );
      if (mounted && data != null) {
        setState(() {
          _allServiceData[service] = data;
          if (_selectedService == service) {
            _detailData = data;
          }
        });
      }
    } catch (_) {}
  }

  List<MediaStaffItem> _resolveStaff(MediaDetailData currentData) {
    final anilistStaff = _allServiceData[ServiceType.anilist]?.sortedStaff;
    if (anilistStaff != null && anilistStaff.isNotEmpty) {
      return anilistStaff;
    }
    if (currentData.sortedStaff.isNotEmpty) {
      return currentData.sortedStaff;
    }
    for (final sData in _allServiceData.values) {
      if (sData.sortedStaff.isNotEmpty) {
        return sData.sortedStaff;
      }
    }
    return const [];
  }

  List<MediaCharacterItem> _resolveCharacters(MediaDetailData currentData) {
    final anilistChars = _allServiceData[ServiceType.anilist]?.sortedCharacters;
    if (anilistChars != null && anilistChars.isNotEmpty) {
      return anilistChars;
    }
    if (currentData.sortedCharacters.isNotEmpty) {
      return currentData.sortedCharacters;
    }
    for (final sData in _allServiceData.values) {
      if (sData.sortedCharacters.isNotEmpty) {
        return sData.sortedCharacters;
      }
    }
    return const [];
  }

  List<ThemeItem> _resolveOpeningThemes(MediaDetailData currentData) {
    final malOps = _allServiceData[ServiceType.mal]?.openingThemes;
    if (malOps != null && malOps.isNotEmpty) {
      return malOps;
    }
    if (currentData.openingThemes.isNotEmpty) {
      return currentData.openingThemes;
    }
    for (final sData in _allServiceData.values) {
      if (sData.openingThemes.isNotEmpty) {
        return sData.openingThemes;
      }
    }
    return const [];
  }

  List<ThemeItem> _resolveEndingThemes(MediaDetailData currentData) {
    final malEds = _allServiceData[ServiceType.mal]?.endingThemes;
    if (malEds != null && malEds.isNotEmpty) {
      return malEds;
    }
    if (currentData.endingThemes.isNotEmpty) {
      return currentData.endingThemes;
    }
    for (final sData in _allServiceData.values) {
      if (sData.endingThemes.isNotEmpty) {
        return sData.endingThemes;
      }
    }
    return const [];
  }

  String _getUserStatusLabel(UnifiedMediaItem liveItem) {
    final firstItem = liveItem.services.values.firstOrNull;
    if (firstItem == null) return AppLocalizations.of(context).addToList;

    final isAnime = liveItem.mediaType == MediaType.anime;
    final total = liveItem.resolvedTotalProgress;
    final progress = firstItem.progress;

    switch (firstItem.status.toLowerCase()) {
      case 'watching':
      case 'reading':
        if (isAnime) {
          return total != null
              ? AppLocalizations.of(
                  context,
                ).watchingProgressTotal(progress.toString(), total.toString())
              : AppLocalizations.of(
                  context,
                ).watchingProgress(progress.toString());
        } else {
          return total != null
              ? AppLocalizations.of(
                  context,
                ).readingProgressTotal(progress.toString(), total.toString())
              : AppLocalizations.of(
                  context,
                ).readingProgress(progress.toString());
        }
      case 'completed':
        return AppLocalizations.of(context).completed;
      case 'on_hold':
        return AppLocalizations.of(context).onHold;
      case 'dropped':
        return AppLocalizations.of(context).dropped;
      case 'plan_to_watch':
      case 'plan_to_read':
        return AppLocalizations.of(context).planToWatch;
      default:
        return AppLocalizations.of(context).edit;
    }
  }

  void _openEditDialog() {
    final liveItem = _getLiveItem();
    showDialog(
      context: context,
      builder: (_) => EditMediaDialog(item: liveItem),
    );
  }

  void _openExternalUrl() async {
    final liveItem = _getLiveItem();
    final serviceItem = liveItem.services[_selectedService];
    final id = serviceItem?.id ?? _detailData?.serviceId ?? liveItem.malId;
    if (id <= 0) return;

    final isAnime = liveItem.mediaType == MediaType.anime;
    final typePath = isAnime ? 'anime' : 'manga';

    Uri? uri;
    switch (_selectedService) {
      case ServiceType.anilist:
        uri = Uri.parse('https://anilist.co/$typePath/$id');
        break;
      case ServiceType.mal:
        uri = Uri.parse('https://myanimelist.net/$typePath/$id');
        break;
      case ServiceType.kitsu:
        uri = Uri.parse('https://kitsu.app/$typePath/$id');
        break;
      case ServiceType.shikimori:
        uri = Uri.parse(
          'https://shikimori.one/${isAnime ? "animes" : "mangas"}/$id',
        );
        break;
      case ServiceType.simkl:
        uri = Uri.parse('https://simkl.com/anime/$id');
        break;
      case ServiceType.mangabaka:
        uri = Uri.parse('https://mangabaka.com/series/$id');
        break;
      case ServiceType.mangaupdates:
        uri = Uri.parse('https://www.mangaupdates.com/series.html?id=$id');
        break;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Uri? _buildExternalUrl() {
    final liveItem = _getLiveItem();
    final serviceItem = liveItem.services[_selectedService];
    final id = serviceItem?.id ?? _detailData?.serviceId ?? liveItem.malId;
    if (id <= 0) return null;

    final isAnime = liveItem.mediaType == MediaType.anime;
    final typePath = isAnime ? 'anime' : 'manga';

    switch (_selectedService) {
      case ServiceType.anilist:
        return Uri.parse('https://anilist.co/$typePath/$id');
      case ServiceType.mal:
        return Uri.parse('https://myanimelist.net/$typePath/$id');
      case ServiceType.kitsu:
        return Uri.parse('https://kitsu.app/$typePath/$id');
      case ServiceType.shikimori:
        return Uri.parse(
          'https://shikimori.one/${isAnime ? "animes" : "mangas"}/$id',
        );
      case ServiceType.simkl:
        return Uri.parse('https://simkl.com/anime/$id');
      case ServiceType.mangabaka:
        return Uri.parse('https://mangabaka.com/series/$id');
      case ServiceType.mangaupdates:
        return Uri.parse('https://www.mangaupdates.com/series.html?id=$id');
    }
  }

  void _shareMedia() {
    final liveItem = _getLiveItem();
    SharePlus.instance.share(ShareParams(text: _buildExternalUrl().toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).mediaLinkShared(
            liveItem.titleFor(ref.read(languageSettingsProvider).titleLanguage),
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liveItem = _getLiveItem();
    final supportedServices = _getSupportedServices();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppLocalizations.of(context).back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          liveItem.titleFor(ref.watch(languageSettingsProvider).titleLanguage),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServiceType>(
                value: _selectedService,
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                borderRadius: BorderRadius.circular(12),
                isDense: true,
                onChanged: (newService) {
                  if (newService != null) {
                    _onSelectService(newService);
                  }
                },
                items: supportedServices.map((s) {
                  final isTracked = liveItem.services.containsKey(s);
                  return DropdownMenuItem<ServiceType>(
                    value: s,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ServiceBadgeChip(service: s, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          s.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isTracked) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: AppLocalizations.of(
              context,
            ).openOnSelectedservice(_selectedService.displayName),
            onPressed: _openExternalUrl,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: AppLocalizations.of(context).share,
            onPressed: _shareMedia,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditDialog,
        icon: const Icon(Icons.edit_rounded),
        label: Text(
          _getUserStatusLabel(liveItem),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDetails(forceRefresh: true),
        child: _buildBody(theme, liveItem, supportedServices),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    UnifiedMediaItem liveItem,
    List<ServiceType> supportedServices,
  ) {
    if (_isLoading && _detailData == null) {
      return MediaDetailSkeleton(liveItem: liveItem);
    }

    if (_errorMessage != null && _detailData == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          alignment: Alignment.center,
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                ).failedToLoadDetailsFromService(_selectedService.displayName),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadDetails(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_detailData == null) {
      return MediaDetailSkeleton(liveItem: liveItem);
    }

    final data = _detailData!;
    final staff = _resolveStaff(data);
    final characters = _resolveCharacters(data);
    final openingThemes = _resolveOpeningThemes(data);
    final endingThemes = _resolveEndingThemes(data);

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaHeaderSection(
            context: context,
            theme: theme,
            liveItem: liveItem,
            data: data,
            titleLanguage: ref.watch(languageSettingsProvider).titleLanguage,
          ),

          const SizedBox(height: 12),
          MediaMultiServiceScoresBar(
            theme: theme,
            supportedServices: supportedServices,
            allServiceData: _allServiceData,
            onSelectService: (service) => _onSelectService(service),
            selectedService: _selectedService,
            item: liveItem,
          ),

          const SizedBox(height: 16),

          if (data.genres.isNotEmpty || data.tags.isNotEmpty) ...[
            MediaGenresRow(theme: theme, data: data),
            const SizedBox(height: 16),
          ],

          MediaDescriptionSection(
            theme: theme,
            item: liveItem,
            allServiceData: _allServiceData,
            selectedService: _selectedService,
            detailData: data,
          ),

          const SizedBox(height: 16),
          if (data.rank != null ||
              data.favorites != null ||
              data.popularity != null ||
              data.trending != null) ...[
            Container(
              key: _sectionKeys.statsKey,
              child: MediaStatsSection(
                context: context,
                theme: theme,
                data: data,
              ),
            ),
            const SizedBox(height: 20),
          ],

          Container(
            key: _sectionKeys.infoKey,
            child: MediaMoreInfoSection(
              context: context,
              theme: theme,
              data: data,
            ),
          ),
          const SizedBox(height: 24),

          if (staff.isNotEmpty || characters.isNotEmpty) ...[
            Container(
              key: _sectionKeys.charactersKey,
              child: MediaCharactersAndStaffSection(
                context: context,
                theme: theme,
                data: data,
                staffOverride: staff,
                charactersOverride: characters,
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (data.rankings.isNotEmpty ||
              data.statusDistribution.isNotEmpty ||
              data.scoreDistribution.isNotEmpty) ...[
            MediaRankingsAndDistributionSection(
              context: context,
              theme: theme,
              data: data,
            ),
            const SizedBox(height: 24),
          ],

          if (openingThemes.isNotEmpty || endingThemes.isNotEmpty) ...[
            MediaMusicThemesSection(
              context: context,
              theme: theme,
              data: data,
              openingThemesOverride: openingThemes,
              endingThemesOverride: endingThemes,
            ),
            const SizedBox(height: 24),
          ],

          Container(
            key: _sectionKeys.relationsKey,
            child: MediaRelationsAndRecommendationsSection(
              theme: theme,
              data: data,
              allServiceData: _allServiceData,
              selectedService: _selectedService,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class GlobalControllerKeys {
  final GlobalKey infoKey = GlobalKey();
  final GlobalKey charactersKey = GlobalKey();
  final GlobalKey relationsKey = GlobalKey();
  final GlobalKey statsKey = GlobalKey();
}
