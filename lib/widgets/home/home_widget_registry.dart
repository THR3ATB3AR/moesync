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
      query: _seasonQuery(MediaDiscoveryCategory.currentSeason, DateTime.now()),
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
      ),
    ),
  ),
  HomeWidgetDefinition(
    id: homeWidgetNextSeasonId,
    icon: Icons.upcoming_rounded,
    title: (l) => l.nextSeason,
    builder: (data) => _DiscoveryWidget(
      data: data,
      query: _seasonQuery(MediaDiscoveryCategory.nextSeason, DateTime.now()),
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
      MediaDiscoveryCategory.currentSeason ||
      MediaDiscoveryCategory.nextSeason =>
        '${_seasonLabel(localizations, query.season!)} ${query.year}',
      MediaDiscoveryCategory.recommended => localizations.recommended,
      MediaDiscoveryCategory.trending => localizations.trending,
      MediaDiscoveryCategory.mostPopular => localizations.mostPopular,
      MediaDiscoveryCategory.newlyAdded => localizations.newlyAdded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          context: data.context,
          title: title,
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
            return HomeHorizontalMediaList(
              context: context,
              ref: ref,
              items: unifiedItems.take(10).toList(),
              theme: data.theme,
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

String _seasonLabel(AppLocalizations localizations, AnimeSeason season) =>
    switch (season) {
      AnimeSeason.winter => localizations.seasonWinter,
      AnimeSeason.spring => localizations.seasonSpring,
      AnimeSeason.summer => localizations.seasonSummer,
      AnimeSeason.fall => localizations.seasonFall,
    };

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
