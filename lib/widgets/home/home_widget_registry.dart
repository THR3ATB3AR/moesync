import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/media_item.dart';
import '../../models/media_discovery.dart';
import '../../providers/providers.dart';
import 'home_horizontal_media_list.dart';
import 'home_section_header.dart';
import 'home_services_overview.dart';
import 'home_stats_row.dart';
import 'home_sync_status_card.dart';
import 'home_widget_ids.dart';
import '../service_badge.dart';
import '../skeleton_loader.dart';

class HomeWidgetData {
  const HomeWidgetData({
    required this.context,
    required this.ref,
    required this.theme,
    required this.auth,
    required this.sync,
    required this.watchingAnime,
    required this.readingManga,
    required this.completedCount,
  });

  final BuildContext context;
  final WidgetRef ref;
  final ThemeData theme;
  final AuthState auth;
  final SyncState sync;
  final List<UnifiedMediaItem> watchingAnime;
  final List<UnifiedMediaItem> readingManga;
  final int completedCount;
}

class HomeWidgetDefinition {
  const HomeWidgetDefinition({
    required this.id,
    required this.icon,
    required this.title,
    required this.builder,
    this.isVisible,
  });

  final String id;
  final IconData icon;
  final String Function(AppLocalizations localizations) title;
  final Widget Function(HomeWidgetData data) builder;
  final bool Function(HomeWidgetData data)? isVisible;
}

final homeWidgetRegistry = List<HomeWidgetDefinition>.unmodifiable([
  HomeWidgetDefinition(
    id: homeWidgetSyncStatusId,
    icon: Icons.sync_rounded,
    title: (l) => l.homeWidgetSyncStatus,
    builder: (data) => HomeSyncStatusCard(
      context: data.context,
      ref: data.ref,
      sync: data.sync,
      auth: data.auth,
      theme: data.theme,
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetServicesId,
    icon: Icons.cloud_outlined,
    title: (l) => l.homeWidgetServiceStatus,
    builder: (data) => HomeServicesOverview(
      context: data.context,
      ref: data.ref,
      auth: data.auth,
      theme: data.theme,
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetStatsId,
    icon: Icons.insights_rounded,
    title: (l) => l.homeWidgetStats,
    builder: (data) => HomeStatsRow(
      context: data.context,
      theme: data.theme,
      animeCount: data.watchingAnime.length,
      mangaCount: data.readingManga.length,
      completed: data.completedCount,
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetConnectServicesId,
    icon: Icons.cloud_sync_outlined,
    title: (l) => l.homeWidgetWelcome,
    isVisible: (data) => data.auth.connectedCount == 0,
    builder: (data) {
      if (data.auth.connectedCount > 0) return const SizedBox.shrink();
      final theme = data.theme;
      final context = data.context;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_sync_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).welcomeToMoeSync,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(
                context,
              ).connectAtLeastOneServiceAccountMyanimelistAnilistKitsuShikimoriOrSimklToDisplayAndSynchronizeYourAnimeMangaLists,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/more/settings/accounts'),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(AppLocalizations.of(context).configureAccounts),
            ),
          ],
        ),
      );
    },
  ),
  HomeWidgetDefinition(
    id: homeWidgetContinueWatchingId,
    icon: Icons.play_circle_outline_rounded,
    title: (l) => l.continueWatching,
    isVisible: (data) => data.auth.connectedCount > 0,
    builder: (data) => _ContinueMediaWidget(
      data: data,
      type: MediaType.anime,
      items: data.watchingAnime,
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetContinueReadingId,
    icon: Icons.menu_book_rounded,
    title: (l) => l.continueReading,
    isVisible: (data) => data.auth.connectedCount > 0,
    builder: (data) => _ContinueMediaWidget(
      data: data,
      type: MediaType.manga,
      items: data.readingManga,
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetCurrentSeasonId,
    icon: Icons.calendar_month_rounded,
    title: (l) => l.currentSeason,
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: _seasonQuery(
        MediaDiscoveryCategory.currentSeason,
        DateTime.now(),
      ).copyWith(includeOtherServices: true),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetRecommendedId,
    icon: Icons.auto_awesome_rounded,
    title: (l) => l.recommended,
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: const MediaDiscoveryQuery(
        category: MediaDiscoveryCategory.recommended,
        includeOtherServices: true,
      ),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetTrendingId,
    icon: Icons.trending_up_rounded,
    title: (l) => l.trending,
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: const MediaDiscoveryQuery(
        category: MediaDiscoveryCategory.trending,
        includeOtherServices: true,
      ),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetNextSeasonId,
    icon: Icons.upcoming_rounded,
    title: (l) => l.nextSeason,
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: _seasonQuery(
        MediaDiscoveryCategory.nextSeason,
        DateTime.now(),
      ).copyWith(includeOtherServices: true),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetMostPopularId,
    icon: Icons.star_rounded,
    title: (l) => l.mostPopular,
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: const MediaDiscoveryQuery(
        category: MediaDiscoveryCategory.mostPopular,
        includeOtherServices: true,
      ),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetNewlyAddedId,
    icon: Icons.new_releases_outlined,
    title: (l) => l.newlyAdded,
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: const MediaDiscoveryQuery(
        category: MediaDiscoveryCategory.newlyAdded,
        includeOtherServices: true,
      ),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetMangaRecommendedId,
    icon: Icons.auto_awesome_rounded,
    title: (l) => '${l.recommended} · ${l.manga}',
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: const MediaDiscoveryQuery(
        category: MediaDiscoveryCategory.recommended,
        mediaType: MediaType.manga,
        includeOtherServices: true,
      ),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetMangaTrendingId,
    icon: Icons.trending_up_rounded,
    title: (l) => '${l.trending} · ${l.manga}',
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: const MediaDiscoveryQuery(
        category: MediaDiscoveryCategory.trending,
        mediaType: MediaType.manga,
        includeOtherServices: true,
      ),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetMangaMostPopularId,
    icon: Icons.local_fire_department_rounded,
    title: (l) => '${l.mostPopular} · ${l.manga}',
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: const MediaDiscoveryQuery(
        category: MediaDiscoveryCategory.mostPopular,
        mediaType: MediaType.manga,
        includeOtherServices: true,
      ),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetMangaNewlyAddedId,
    icon: Icons.new_releases_outlined,
    title: (l) => '${l.newlyAdded} · ${l.manga}',
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: const MediaDiscoveryQuery(
        category: MediaDiscoveryCategory.newlyAdded,
        mediaType: MediaType.manga,
        includeOtherServices: true,
      ),
    ),
  ),
]);

MediaDiscoveryQuery _seasonQuery(
  MediaDiscoveryCategory category,
  DateTime now,
) {
  final season = category == MediaDiscoveryCategory.nextSeason
      ? AnimeSeason.forDate(now).next
      : AnimeSeason.forDate(now);
  final crossesYear =
      category == MediaDiscoveryCategory.nextSeason &&
      AnimeSeason.forDate(now) == AnimeSeason.fall;
  return MediaDiscoveryQuery(
    category: category,
    season: season,
    year: now.year + (crossesYear ? 1 : 0),
  );
}

class _DiscoveryWidget extends ConsumerWidget {
  const _DiscoveryWidget({required this.data, required this.query});

  final HomeWidgetData data;
  final MediaDiscoveryQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final result = ref.watch(mediaDiscoveryProvider(query));
    final title = switch (query.category) {
      MediaDiscoveryCategory.currentSeason => localizations.currentSeason,
      MediaDiscoveryCategory.nextSeason => localizations.nextSeason,
      MediaDiscoveryCategory.recommended => localizations.recommended,
      MediaDiscoveryCategory.trending => localizations.trending,
      MediaDiscoveryCategory.mostPopular => localizations.mostPopular,
      MediaDiscoveryCategory.newlyAdded => localizations.newlyAdded,
    };
    final sectionTitle = query.mediaType == MediaType.manga
        ? '$title · ${localizations.manga}'
        : title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          context: data.context,
          title: sectionTitle,
          icon: switch (query.category) {
            MediaDiscoveryCategory.currentSeason ||
            MediaDiscoveryCategory.nextSeason => Icons.calendar_month_rounded,
            MediaDiscoveryCategory.recommended => Icons.auto_awesome_rounded,
            MediaDiscoveryCategory.trending => Icons.trending_up_rounded,
            MediaDiscoveryCategory.mostPopular =>
              Icons.local_fire_department_rounded,
            MediaDiscoveryCategory.newlyAdded => Icons.new_releases_outlined,
          },
          onViewAll: () => GoRouter.of(data.context).push(
            '/discover/${query.category.name}',
            extra: query.copyWith(includeOtherServices: true),
          ),
        ),
        const SizedBox(height: 12),
        result.when(
          data: (items) {
            final unifiedItems = unifyDiscoveryItems(items);
            if (unifiedItems.isEmpty) {
              return Text(
                localizations.noSearchResults,
                style: data.theme.textTheme.bodyMedium?.copyWith(
                  color: data.theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return SizedBox(
              height: 245,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: unifiedItems.length > 10 ? 10 : unifiedItems.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: 130,
                  child: MediaDiscoveryCard(
                    item: unifiedItems[index],
                    type: query.mediaType,
                    horizontal: true,
                  ),
                ),
              ),
            );
          },
          error: (error, stackTrace) => Text(
            localizations.failedToLoadMedia,
            style: data.theme.textTheme.bodyMedium?.copyWith(
              color: data.theme.colorScheme.error,
            ),
          ),
          loading: () => const HomeHorizontalMediaListSkeleton(),
        ),
      ],
    );
  }
}

class MediaDiscoveryCard extends ConsumerWidget {
  const MediaDiscoveryCard({
    required this.item,
    required this.type,
    this.horizontal = false,
    super.key,
  });

  final UnifiedMediaItem item;
  final MediaType type;
  final bool horizontal;

  UnifiedMediaItem? _findLibraryEntry(List<UnifiedMediaItem> library) {
    for (final entry in library) {
      if (entry.mediaType != type) continue;
      if (item.malId > 0 && entry.malId == item.malId) return entry;
      if (item.services.entries.any(
        (service) => entry.services[service.key]?.id == service.value.id,
      )) {
        return entry;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final titleLanguage = ref.watch(languageSettingsProvider).titleLanguage;
    final library = ref.watch(mediaLibraryProvider).unifiedItems;
    final libraryEntry = _findLibraryEntry(library);
    final statusEntry = libraryEntry?.services.values.firstOrNull;
    final score = item.malScore;
    final radius = BorderRadius.circular(14);
    final cachedServices = item.mediaType == MediaType.anime
        ? ref
              .watch(animeApiMappingServiceProvider)
              .findMappedServices(item.malId)
        : ref.watch(mangaMappingServiceProvider).findMappedServices(item.malId);
    final displayServices = {...item.services.keys, ...cachedServices}.toList()
      ..sort((first, second) => first.index.compareTo(second.index));

    return InkWell(
      borderRadius: radius,
      onTap: () => GoRouter.of(context).push('/mediaDetails', extra: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 130 / 155,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.posterImage.isEmpty
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.movie_outlined),
                        )
                      : CachedNetworkImage(
                          imageUrl: item.posterImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                  if (statusEntry != null)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Tooltip(
                        message: getStatusLabel(
                          statusEntry.status,
                          type,
                          context,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              statusEntry.status,
                            ).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              _statusIcon(statusEntry.status),
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (score > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.titleFor(titleLanguage),
            maxLines: horizontal ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 46),
            child: Wrap(
              spacing: 3,
              runSpacing: 2,
              clipBehavior: Clip.hardEdge,
              children: displayServices
                  .map(
                    (service) => ServiceBadgeChip(
                      service: service,
                      size: 11,
                      compact: true,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) => switch (status.toLowerCase()) {
    'watching' || 'reading' => Icons.play_circle_fill_rounded,
    'completed' => Icons.check_circle_rounded,
    'on_hold' => Icons.pause_circle_filled_rounded,
    'dropped' => Icons.cancel_rounded,
    _ => Icons.bookmark_add_rounded,
  };
}

class _ContinueMediaWidget extends StatelessWidget {
  const _ContinueMediaWidget({
    required this.data,
    required this.type,
    required this.items,
  });

  final HomeWidgetData data;
  final MediaType type;
  final List<UnifiedMediaItem> items;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(data.context);
    final isAnime = type == MediaType.anime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          context: data.context,
          title: isAnime
              ? localizations.continueWatching
              : localizations.continueReading,
          icon: isAnime
              ? Icons.play_circle_outline_rounded
              : Icons.menu_book_rounded,
          onViewAll: () {
            data.ref.read(mediaLibraryProvider.notifier).setType(type);
            data.ref
                .read(mediaLibraryProvider.notifier)
                .setStatusFilter('watching');
            GoRouter.of(data.context).go(isAnime ? '/anime' : '/manga');
          },
        ),
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          HomeHorizontalMediaList(
            context: data.context,
            ref: data.ref,
            items: items,
            theme: data.theme,
          )
        else
          const HomeHorizontalMediaListSkeleton(),
      ],
    );
  }
}
