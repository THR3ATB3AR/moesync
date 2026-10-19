import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/home/home_horizontal_media_list.dart';
import 'package:moesync/widgets/home/home_section_header.dart';
import 'package:moesync/widgets/home/home_services_overview.dart';
import 'package:moesync/widgets/home/home_stats_row.dart';
import 'package:moesync/widgets/home/home_sync_status_card.dart';
import 'package:moesync/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/media_item.dart';
import '../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final library = ref.watch(mediaLibraryProvider);
    final sync = ref.watch(syncProvider);

    final watchingAnime = library.unifiedItems
        .where(
          (u) =>
              u.mediaType == MediaType.anime &&
              u.services.values.any((s) => s.status == 'watching'),
        )
        .toList();

    final readingManga = library.unifiedItems
        .where(
          (u) =>
              u.mediaType == MediaType.manga &&
              u.services.values.any((s) => s.status == 'watching'),
        )
        .toList();

    final completedCount = library.unifiedItems
        .where((u) => u.services.values.any((s) => s.status == 'completed'))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/icon/png/moesync-icon-mono.png',
                width: 50,
                height: 50,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MoeSync',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).allInOneUnifiedAnimeManga,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).refreshLibrary,
            onPressed: () {
              ref.read(mediaLibraryProvider.notifier).loadItems();
              ref.read(syncProvider.notifier).scanDiffs();
            },
            icon: library.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).settingsAccounts,
            onPressed: () => context.push('/more/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(mediaLibraryProvider.notifier)
              .loadItems(forceRefresh: true);
          await ref.read(syncProvider.notifier).scanDiffs(forceRefresh: true);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            HomeSyncStatusCard(
              context: context,
              ref: ref,
              sync: sync,
              auth: auth,
              theme: theme,
            ),
            const SizedBox(height: 20),

            HomeServicesOverview(
              context: context,
              ref: ref,
              auth: auth,
              theme: theme,
            ),
            const SizedBox(height: 20),

            HomeStatsRow(
              context: context,
              theme: theme,
              animeCount: watchingAnime.length,
              mangaCount: readingManga.length,
              completed: completedCount,
            ),
            const SizedBox(height: 24),

            if (auth.connectedCount == 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
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
                      AppLocalizations.of(context).welcomeToAnisync,
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
                      label: Text(
                        AppLocalizations.of(context).configureAccounts,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (auth.connectedCount > 0) ...[
              HomeSectionHeader(
                context: context,
                title: AppLocalizations.of(context).continueWatching,
                icon: Icons.play_circle_outline_rounded,
                onViewAll: () {
                  ref
                      .read(mediaLibraryProvider.notifier)
                      .setType(MediaType.anime);
                  ref
                      .read(mediaLibraryProvider.notifier)
                      .setStatusFilter('watching');
                  context.go('/anime');
                },
              ),
              const SizedBox(height: 12),
              if (watchingAnime.isNotEmpty) ...[
                HomeHorizontalMediaList(
                  context: context,
                  ref: ref,
                  items: watchingAnime,
                  theme: theme,
                ),
                const SizedBox(height: 24),
              ] else ...[
                HomeHorizontalMediaListSkeleton(),
                const SizedBox(height: 24),
              ],

              HomeSectionHeader(
                context: context,
                title: AppLocalizations.of(context).continueReading,
                icon: Icons.menu_book_rounded,
                onViewAll: () {
                  ref
                      .read(mediaLibraryProvider.notifier)
                      .setType(MediaType.manga);
                  ref
                      .read(mediaLibraryProvider.notifier)
                      .setStatusFilter('watching');
                  context.go('/manga');
                },
              ),
              const SizedBox(height: 12),
              if (readingManga.isNotEmpty) ...[
                HomeHorizontalMediaList(
                  context: context,
                  ref: ref,
                  items: readingManga,
                  theme: theme,
                ),
                const SizedBox(height: 24),
              ] else ...[
                HomeHorizontalMediaListSkeleton(),
                const SizedBox(height: 24),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
