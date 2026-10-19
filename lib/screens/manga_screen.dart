import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/widgets/media/media_grid_card.dart';
import 'package:moesync/widgets/media/media_list_card.dart';
import 'package:moesync/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/media_item.dart';
import '../providers/providers.dart';
import '../widgets/search_dialog.dart';
import '../widgets/service_badge.dart';
import '../widgets/service_errors_dialog.dart';
import '../widgets/media/media_sort_dialog.dart';

class MangaScreen extends ConsumerStatefulWidget {
  const MangaScreen({super.key});

  @override
  ConsumerState<MangaScreen> createState() => _MangaScreenState();
}

class _MangaScreenState extends ConsumerState<MangaScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TabController _tabController;

  static const _tabKeys = [
    'reading',
    'plan_to_read',
    'completed',
    'on_hold',
    'dropped',
    'all',
  ];

  @override
  void initState() {
    super.initState();
    final filter = ref.read(mangaFilterProvider);
    _searchController = TextEditingController(text: filter.searchQuery);

    int initialIndex = _tabKeys.indexOf(filter.status);
    if (initialIndex < 0) initialIndex = 0;
    _tabController = TabController(
      length: _tabKeys.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final currentKey = _tabKeys[_tabController.index];
      final currentFilter = ref.read(mangaFilterProvider);
      if (currentFilter.status != currentKey) {
        ref.read(mangaFilterProvider.notifier).setStatus(currentKey);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _tabLabel(BuildContext context, String key) {
    final l = AppLocalizations.of(context);
    switch (key) {
      case 'reading':
        return l.reading;
      case 'plan_to_read':
        return l.planToRead;
      case 'completed':
        return l.completed;
      case 'on_hold':
        return l.onHold;
      case 'dropped':
        return l.dropped;
      default:
        return l.all;
    }
  }

  void _showSortMenu(BuildContext context) {
    final filter = ref.read(mangaFilterProvider);
    final filterNotifier = ref.read(mangaFilterProvider.notifier);
    MediaSortDialog.show(
      context: context,
      currentField: filter.sortField,
      currentDirection: filter.sortDirection,
      onSortChanged: (field, dir) {
        filterNotifier.setSort(field, direction: dir);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final library = ref.watch(mediaLibraryProvider);
    final notifier = ref.read(mediaLibraryProvider.notifier);
    final viewMode = ref.watch(mediaViewModeProvider);
    final titleLanguage = ref.watch(languageSettingsProvider).titleLanguage;
    final filter = ref.watch(mangaFilterProvider);
    final filterNotifier = ref.read(mangaFilterProvider.notifier);

    ref.listen<MediaFilterState>(mangaFilterProvider, (previous, next) {
      if (previous?.status != next.status) {
        final targetIndex = _tabKeys.indexOf(next.status);
        if (targetIndex >= 0 &&
            _tabController.index != targetIndex &&
            !_tabController.indexIsChanging) {
          _tabController.animateTo(targetIndex);
        }
      }
    });

    if (_searchController.text != filter.searchQuery &&
        _searchController.selection.baseOffset == -1) {
      _searchController.text = filter.searchQuery;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).mangaCollection,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (library.serviceErrors.isNotEmpty)
            IconButton(
              tooltip: AppLocalizations.of(
                context,
              ).detectedServiceErrors(library.serviceErrors.length),
              icon: Badge(
                label: Text('${library.serviceErrors.length}'),
                backgroundColor: theme.colorScheme.error,
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                ),
              ),
              onPressed: () {
                ServiceErrorsDialog.show(
                  context,
                  errors: library.serviceErrors,
                  onRetry: () => notifier.loadItems(),
                );
              },
            ),
          IconButton(
            tooltip: viewMode == MediaViewMode.grid
                ? AppLocalizations.of(context).switchToListView
                : AppLocalizations.of(context).switchToGridView,
            onPressed: () {
              ref
                  .read(mediaViewModeProvider.notifier)
                  .setMode(
                    viewMode == MediaViewMode.grid
                        ? MediaViewMode.list
                        : MediaViewMode.grid,
                  );
            },
            icon: Icon(
              viewMode == MediaViewMode.grid
                  ? Icons.view_agenda_rounded
                  : Icons.grid_view_rounded,
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).refresh,
            onPressed: () => notifier.loadItems(),
            icon: library.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).searchMangaTitles,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: filter.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                filterNotifier.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    onChanged: (val) => filterNotifier.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: AppLocalizations.of(context).filterByService,
                  initialValue: filter.service?.name ?? 'all',
                  onSelected: (val) {
                    if (val == 'all') {
                      filterNotifier.setService(null);
                    } else {
                      final selected = ServiceType.values.firstWhere(
                        (s) => s.name == val,
                      );
                      filterNotifier.setService(selected);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'all',
                      child: Text(
                        AppLocalizations.of(context).allServicesUnified,
                      ),
                    ),
                    const PopupMenuDivider(),
                    ...ServiceType.values
                        .where((s) => s != ServiceType.simkl)
                        .map(
                          (s) => PopupMenuItem(
                            value: s.name,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ServiceBadge(service: s, size: 18),
                                const SizedBox(width: 8),
                                Text(s.displayName),
                              ],
                            ),
                          ),
                        ),
                  ],
                  child: Chip(
                    avatar: filter.service != null
                        ? ServiceBadge(
                            service: filter.service!,
                            size: 16,
                            compact: true,
                          )
                        : Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    label: Text(
                      filter.service != null
                          ? filter.service!.displayName
                          : AppLocalizations.of(context).allServices,
                    ),
                    onDeleted: filter.service != null
                        ? () => filterNotifier.setService(null)
                        : null,
                    backgroundColor: filter.service != null
                        ? theme.colorScheme.primaryContainer
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: AppLocalizations.of(
                    context,
                  ).sortLabel(filter.sortField.getLabel(context)),
                  onPressed: () => _showSortMenu(context),
                  icon: Icon(
                    filter.sortDirection == SortDirection.descending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: _tabKeys
                  .map((key) => Tab(text: _tabLabel(context, key)))
                  .toList(),
            ),
          ),

          Expanded(
            child:
                library.isLoading &&
                    !library.unifiedItems.any(
                      (item) => item.mediaType == MediaType.manga,
                    )
                ? MediaScreenSkeleton(viewType: viewMode)
                : TabBarView(
                    controller: _tabController,
                    children: _tabKeys.map((key) {
                      return _buildTabContent(
                        context,
                        key,
                        library.unifiedItems,
                        filter,
                        viewMode,
                        auth.connectedCount,
                        theme,
                        titleLanguage,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const SearchMediaDialog(mediaType: MediaType.manga),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context).addManga),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    String statusKey,
    List<UnifiedMediaItem> unifiedItems,
    MediaFilterState filter,
    MediaViewMode viewMode,
    int connectedCount,
    ThemeData theme,
    TitleLanguage titleLanguage,
  ) {
    final mangaItems = unifiedItems.where((u) {
      if (u.mediaType != MediaType.manga) return false;

      if (!u.matchesTitleQuery(filter.searchQuery)) {
        return false;
      }

      if (filter.service != null && !u.services.containsKey(filter.service)) {
        return false;
      }

      if (statusKey != 'all') {
        final hasStatus = u.services.values.any((item) {
          final s = item.status.toLowerCase();
          if (statusKey == 'reading' || statusKey == 'watching') {
            return s == 'reading' || s == 'watching';
          }
          if (statusKey == 'plan_to_read' || statusKey == 'plan_to_watch') {
            return s == 'plan_to_read' || s == 'plan_to_watch';
          }
          return s == statusKey.toLowerCase();
        });
        if (!hasStatus) return false;
      }

      return true;
    }).toList();

    mangaItems.sort(
      (a, b) => compareUnifiedMediaItems(
        a,
        b,
        filter.sortField,
        filter.sortDirection,
        titleLanguage,
      ),
    );

    Widget content;
    if (mangaItems.isEmpty) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          alignment: Alignment.center,
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                connectedCount == 0
                    ? Icons.cloud_off_rounded
                    : Icons.menu_book_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                connectedCount == 0
                    ? AppLocalizations.of(context).noAccountsConnected
                    : AppLocalizations.of(context).noMangaFound,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                connectedCount == 0
                    ? AppLocalizations.of(
                        context,
                      ).connectYourMyanimelistAnilistKitsuOrShikimoriAccountInSettingsToViewYourManga
                    : AppLocalizations.of(
                        context,
                      ).tryAdjustingTheSearchOrFilterSettings,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (connectedCount == 0) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.push('/more/settings'),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                    AppLocalizations.of(context).connectAccountsInSettings,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (viewMode == MediaViewMode.grid) {
      content = GridView.builder(
        key: PageStorageKey('manga_grid_$statusKey'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: mangaItems.length,
        itemBuilder: (context, index) {
          final item = mangaItems[index];
          return MediaGridCard(item: item, type: MediaType.manga);
        },
      );
    } else {
      content = ListView.builder(
        key: PageStorageKey('manga_list_$statusKey'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: mangaItems.length,
        itemBuilder: (context, index) {
          final item = mangaItems[index];
          return MediaListCard(item: item, type: MediaType.manga);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(mediaLibraryProvider.notifier)
            .loadItems(forceRefresh: true);
      },
      child: content,
    );
  }
}
