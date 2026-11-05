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
  List<MediaItem> _results = const [];
  List<({String query, MediaType mediaType})> _history = const [];
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search([String? value]) async {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) return;

    final generation = ++_searchGeneration;
    final storage = ref.read(storageServiceProvider);
    final cached = storage.getCachedSearchResults(query, _mediaType);
    setState(() {
      _hasSearched = true;
      _results = cached ?? const [];
      _hasCachedResults = cached != null;
      _isSearching = true;
      _error = null;
    });

    await storage.saveMediaSearchHistory(query, _mediaType);
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _history = storage.getMediaSearchHistory();
    });

    try {
      final anilist = ref.read(anilistServiceProvider);
      final mal = ref.read(malServiceProvider);
      var freshResults = await anilist.search(query, _mediaType);
      if (freshResults.isEmpty) {
        freshResults = await mal.search(query, _mediaType);
      }

      if (freshResults.isNotEmpty) {
        await storage.saveCachedSearchResults(query, _mediaType, freshResults);
      }
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        if (freshResults.isNotEmpty || cached == null) {
          _results = freshResults;
          _hasCachedResults = false;
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

  void _selectHistoryEntry(({String query, MediaType mediaType}) entry) {
    setState(() {
      _mediaType = entry.mediaType;
      _controller.text = entry.query;
    });
    _search(entry.query);
  }

  Future<void> _clearHistory() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearMediaSearchHistory();
    if (!mounted) return;
    setState(() => _history = const []);
  }

  UnifiedMediaItem? _findLibraryItem(
    MediaItem result,
    List<UnifiedMediaItem> library,
  ) {
    for (final item in library) {
      if (item.mediaType != _mediaType) continue;
      if (result.malId != null &&
          result.malId! > 0 &&
          item.malId == result.malId) {
        return item;
      }
      if (item.services.values.any(
        (serviceItem) =>
            serviceItem.service == result.service &&
            serviceItem.id == result.id,
      )) {
        return item;
      }
    }
    return null;
  }

  void _openDetails(MediaItem result, List<UnifiedMediaItem> library) {
    final existing = _findLibraryItem(result, library);
    final unified =
        existing ??
        UnifiedMediaItem(
          malId:
              result.malId ??
              (result.service == ServiceType.mal ? result.id : 0),
          title: result.title,
          posterImage: result.posterImage,
          mediaType: _mediaType,
          services: {result.service: result},
        );
    context.push('/mediaDetails', extra: unified);
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
          onChanged: (_) {
            _searchGeneration++;
            setState(() {
              _results = const [];
              _hasSearched = false;
              _isSearching = false;
              _hasCachedResults = false;
              _error = null;
            });
          },
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: searchHint,
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l.searchMediaHint,
                    onPressed: () {
                      _searchGeneration++;
                      _controller.clear();
                      setState(() {
                        _results = const [];
                        _hasSearched = false;
                        _isSearching = false;
                        _hasCachedResults = false;
                        _error = null;
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l.searchByTitle,
            onPressed: _isSearching ? null : () => _search(),
            icon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
          ),
        ],
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
                  _search();
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

  final MediaItem item;
  final UnifiedMediaItem? ownedItem;
  final TitleLanguage titleLanguage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final type = item.mediaType;
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
                  height: 114,
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
                  height: 114,
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
                          ServiceBadgeChip(
                            service: item.service,
                            size: 14,
                            compact: true,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.totalProgress != null
                            ? type == MediaType.anime
                                  ? l.dataEpisodesEpisodes(item.totalProgress!)
                                  : l.dataChaptersChapters(item.totalProgress!)
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
