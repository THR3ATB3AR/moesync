import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/service_badge.dart';

class MediaSearchScreen extends ConsumerStatefulWidget {
  const MediaSearchScreen({super.key});

  @override
  ConsumerState<MediaSearchScreen> createState() => _MediaSearchScreenState();
}

class _MediaSearchScreenState extends ConsumerState<MediaSearchScreen> {
  final _controller = TextEditingController();
  MediaType _mediaType = MediaType.anime;
  List<UnifiedMediaItem> _results = const [];
  List<({String query, MediaType mediaType})> _history = const [];
  Timer? _searchDebounce;
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _hasCachedResults = false;
  String? _error;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _history = ref.read(storageServiceProvider).getMediaSearchHistory();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value, {bool immediate = false}) {
    _searchDebounce?.cancel();
    final query = value.trim();
    final generation = ++_searchGeneration;
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _hasSearched = false;
        _isSearching = false;
        _hasCachedResults = false;
        _error = null;
      });
      return;
    }

    final storage = ref.read(storageServiceProvider);
    final mediaType = _mediaType;
    final cachedResults =
        storage.getCachedSearchResults(query, mediaType) ?? [];
    final libraryResults = ref
        .read(mediaLibraryProvider)
        .unifiedItems
        .where(
          (item) =>
              item.mediaType == mediaType && item.matchesTitleQuery(query),
        );
    final localResults = _mergeSearchResults([
      ...cachedResults.expand((item) => item.services.values),
      ...libraryResults.expand((item) => item.services.values),
    ]);
    final cached = localResults.isEmpty ? null : localResults;
    setState(() {
      _hasSearched = true;
      _results = localResults;
      _hasCachedResults = cached != null;
      _isSearching = true;
      _error = null;
    });

    if (immediate) {
      unawaited(_performSearch(query, mediaType, generation, cached));
    } else {
      _searchDebounce = Timer(
        const Duration(milliseconds: 350),
        () => unawaited(_performSearch(query, mediaType, generation, cached)),
      );
    }
  }

  Future<void> _performSearch(
    String query,
    MediaType mediaType,
    int generation,
    List<UnifiedMediaItem>? cached,
  ) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveMediaSearchHistory(query, mediaType);
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _history = storage.getMediaSearchHistory();
    });

    try {
      final searches = <(ServiceType, Future<List<MediaItem>>)>[
        (
          ServiceType.anilist,
          ref.read(anilistServiceProvider).search(query, mediaType),
        ),
        (
          ServiceType.mal,
          ref.read(malServiceProvider).search(query, mediaType),
        ),
        (
          ServiceType.kitsu,
          ref.read(kitsuServiceProvider).search(query, mediaType),
        ),
        (
          ServiceType.shikimori,
          ref.read(shikimoriServiceProvider).search(query, mediaType),
        ),
        if (mediaType == MediaType.anime)
          (
            ServiceType.simkl,
            ref.read(simklServiceProvider).search(query, mediaType),
          ),
      ];
      final failures = <String>[];
      final serviceResults = await Future.wait(
        searches.map((search) async {
          try {
            return await search.$2;
          } catch (error) {
            failures.add('${search.$1.displayName}: $error');
            debugPrint('Media search failed for ${search.$1.name}: $error');
            return <MediaItem>[];
          }
        }),
      );
      final freshResults = _mergeSearchResults([
        ...?cached?.expand((item) => item.services.values),
        ...serviceResults.expand((items) => items),
      ]);

      if (!mounted || generation != _searchGeneration) return;
      if (freshResults.isNotEmpty) {
        await storage.saveCachedSearchResults(query, mediaType, freshResults);
      }
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        if (freshResults.isNotEmpty || cached == null) {
          _results = freshResults;
          _hasCachedResults = false;
        }
        if (freshResults.isEmpty && failures.isNotEmpty) {
          _error = AppLocalizations.of(
            context,
          ).failedToSearch(failures.join('\n'));
        }
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _error = AppLocalizations.of(context).failedToSearch(error.toString());
        _isSearching = false;
      });
    }
  }

  List<UnifiedMediaItem> _mergeSearchResults(Iterable<MediaItem> items) {
    final merged = <String, UnifiedMediaItem>{};
    for (final item in items) {
      final malId =
          item.malId ?? (item.service == ServiceType.mal ? item.id : null);
      final mappedMalId = malId != null && malId > 0
          ? malId
          : _mappedMalId(item);
      final key = mappedMalId > 0
          ? 'mal:$mappedMalId'
          : '${item.service.name}:${item.id}';
      final existing = merged[key];
      if (existing == null) {
        merged[key] = UnifiedMediaItem(
          malId: mappedMalId,
          title: item.title,
          posterImage: item.posterImage,
          mediaType: item.mediaType,
          services: {item.service: item},
        );
        continue;
      }

      final services = Map<ServiceType, MediaItem>.from(existing.services)
        ..[item.service] = item;
      merged[key] = existing.copyWith(
        title: existing.title.isNotEmpty ? existing.title : item.title,
        posterImage: existing.posterImage.isNotEmpty
            ? existing.posterImage
            : item.posterImage,
        services: services,
      );
    }
    return merged.values.toList();
  }

  int _mappedMalId(MediaItem item) {
    if (_mediaType == MediaType.anime) {
      return ref
          .read(animeApiMappingServiceProvider)
          .findMalId(item.service, item.id);
    }
    return ref
        .read(mangaMappingServiceProvider)
        .findMalId(item.service, item.id);
  }

  void _selectHistoryEntry(({String query, MediaType mediaType}) entry) {
    setState(() {
      _mediaType = entry.mediaType;
      _controller.text = entry.query;
    });
    _scheduleSearch(entry.query, immediate: true);
  }

  Future<void> _clearHistory() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearMediaSearchHistory();
    if (!mounted) return;
    setState(() => _history = const []);
  }

  UnifiedMediaItem? _findLibraryItem(
    UnifiedMediaItem result,
    List<UnifiedMediaItem> library,
  ) {
    for (final item in library) {
      if (item.mediaType != _mediaType) continue;
      if (result.malId > 0 && item.malId == result.malId) {
        return item;
      }
      if (result.services.entries.any(
        (entry) => item.services[entry.key]?.id == entry.value.id,
      )) {
        return item;
      }
    }
    return null;
  }

  void _openDetails(UnifiedMediaItem result, List<UnifiedMediaItem> library) {
    final existing = _findLibraryItem(result, library);
    context.push('/mediaDetails', extra: existing ?? result);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final library = ref.watch(mediaLibraryProvider).unifiedItems;
    final titleLanguage = ref.watch(languageSettingsProvider).titleLanguage;
    final searchHint = l.searchMediaHint;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _scheduleSearch,
          onSubmitted: (value) => _scheduleSearch(value, immediate: true),
          decoration: InputDecoration(
            hintText: searchHint,
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l.searchMediaHint,
                    onPressed: () {
                      _controller.clear();
                      _scheduleSearch('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SegmentedButton<MediaType>(
              segments: [
                ButtonSegment(
                  value: MediaType.anime,
                  icon: const Icon(Icons.movie_filter_outlined),
                  label: Text(l.anime),
                ),
                ButtonSegment(
                  value: MediaType.manga,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(l.manga),
                ),
              ],
              selected: {_mediaType},
              onSelectionChanged: (selection) {
                final selected = selection.first;
                setState(() => _mediaType = selected);
                if (_controller.text.trim().isNotEmpty) {
                  _scheduleSearch(_controller.text);
                } else {
                  setState(() {
                    _results = const [];
                    _hasSearched = false;
                    _error = null;
                  });
                }
              },
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(minHeight: 2),
          if (_hasCachedResults)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.showingCachedResults,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          Expanded(
            child: _hasSearched
                ? _results.isEmpty && !_isSearching
                      ? Center(
                          child: Text(
                            l.noSearchResults,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            final ownedItem = _findLibraryItem(result, library);
                            return _MediaSearchResultCard(
                              item: result,
                              ownedItem: ownedItem,
                              titleLanguage: titleLanguage,
                              onTap: () => _openDetails(result, library),
                            );
                          },
                        )
                : _buildHistory(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.manage_search_rounded,
                size: 52,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(l.searchByTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l.noSearchHistory,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.searchHistory,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: Text(l.clearSearchHistory),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ..._history.map(
          (entry) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              entry.mediaType == MediaType.anime
                  ? Icons.movie_filter_outlined
                  : Icons.menu_book_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              entry.query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              entry.mediaType == MediaType.anime ? l.anime : l.manga,
            ),
            trailing: const Icon(Icons.north_west_rounded, size: 18),
            onTap: () => _selectHistoryEntry(entry),
          ),
        ),
      ],
    );
  }
}

class _MediaSearchResultCard extends StatelessWidget {
  const _MediaSearchResultCard({
    required this.item,
    required this.ownedItem,
    required this.titleLanguage,
    required this.onTap,
  });

  final UnifiedMediaItem item;
  final UnifiedMediaItem? ownedItem;
  final TitleLanguage titleLanguage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final type = item.mediaType;
    final metadataItem = item.services.values.firstWhere(
      (serviceItem) =>
          serviceItem.mediaFormat != null ||
          serviceItem.releaseSeason != null ||
          serviceItem.releaseYear != null,
      orElse: () => item.services.values.first,
    );
    final ownedService = ownedItem?.services.values.firstOrNull;
    final status = ownedService?.status;
    final statusColor = status == null
        ? theme.colorScheme.onSurfaceVariant
        : getStatusColor(status);
    final statusIcon = switch (status) {
      'watching' || 'reading' => Icons.play_circle_outline_rounded,
      'completed' => Icons.check_circle_outline_rounded,
      'on_hold' => Icons.pause_circle_outline_rounded,
      'dropped' => Icons.cancel_outlined,
      'plan_to_watch' || 'plan_to_read' => Icons.bookmark_border_rounded,
      _ => Icons.add_circle_outline_rounded,
    };
    final season = switch (metadataItem.releaseSeason?.toUpperCase()) {
      'WINTER' => l.seasonWinter,
      'SPRING' => l.seasonSpring,
      'SUMMER' => l.seasonSummer,
      'FALL' || 'AUTUMN' => l.seasonFall,
      final value => value,
    };
    final release = [
      ?season,
      if (metadataItem.releaseYear != null) metadataItem.releaseYear.toString(),
    ].join(' ');
    final metadata = [
      if (metadataItem.mediaFormat?.isNotEmpty == true)
        metadataItem.mediaFormat!.replaceAll('_', ' '),
      if (release.isNotEmpty) release,
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 82,
                  height: 132,
                  child: item.posterImage.isEmpty
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            type == MediaType.anime
                                ? Icons.movie_outlined
                                : Icons.menu_book_outlined,
                            size: 36,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: item.posterImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 132,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.titleFor(titleLanguage),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              status == null
                                  ? l.notOnList
                                  : getStatusLabel(status, type, context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 3,
                            children: item.services.keys
                                .map(
                                  (service) => ServiceBadgeChip(
                                    service: service,
                                    size: 14,
                                    compact: true,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          metadata.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        item.resolvedTotalProgress != null
                            ? type == MediaType.anime
                                  ? l.dataEpisodesEpisodes(
                                      item.resolvedTotalProgress!,
                                    )
                                  : l.dataChaptersChapters(
                                      item.resolvedTotalProgress!,
                                    )
                            : l.ongoing,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
