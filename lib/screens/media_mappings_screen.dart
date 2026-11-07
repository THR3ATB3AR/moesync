import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import '../models/media_item.dart';
import '../models/media_mapping.dart';
import '../providers/providers.dart';

enum _MappingMode { suggestions, manual, saved }

class MediaMappingsScreen extends ConsumerStatefulWidget {
  const MediaMappingsScreen({super.key});

  @override
  ConsumerState<MediaMappingsScreen> createState() =>
      _MediaMappingsScreenState();
}

class _MediaMappingsScreenState extends ConsumerState<MediaMappingsScreen> {
  MediaType _mediaType = MediaType.anime;
  _MappingMode _mode = _MappingMode.suggestions;
  String _query = '';
  Set<String> _selectedItems = {};
  Set<String> _selectedSuggestions = {};
  String? _cachedSuggestionKey;
  List<SuggestedMediaMapping> _cachedSuggestions = const [];
  bool _isSaving = false;

  String _itemKey(UnifiedMediaItem item) {
    final keys =
        item.services.entries
            .map(
              (entry) =>
                  '${entry.key.name}:${entry.value.id}:${entry.value.mediaType.name}',
            )
            .toList()
          ..sort();
    return keys.join('|');
  }

  List<MediaMappingIdentity> _identitiesFor(Iterable<UnifiedMediaItem> items) =>
      [
        for (final item in items)
          for (final serviceItem in item.services.values)
            MediaMappingIdentity.fromItem(serviceItem),
      ];

  List<MediaMappingIdentity> _suggestionIdentities(
    SuggestedMediaMapping suggestion,
  ) => _identitiesFor(suggestion.items);

  void _toggleSuggestion(SuggestedMediaMapping suggestion) {
    final key = suggestion.key;
    final selected = Set<String>.from(_selectedSuggestions);
    if (!selected.add(key)) {
      selected.remove(key);
    }
    setState(() => _selectedSuggestions = selected);
  }

  Future<void> _saveSelectedSuggestions(
    List<SuggestedMediaMapping> suggestions,
  ) async {
    if (_isSaving || _selectedSuggestions.isEmpty) return;
    setState(() => _isSaving = true);
    var savedCount = 0;
    Object? saveError;
    try {
      final selected = suggestions
          .where((suggestion) => _selectedSuggestions.contains(suggestion.key))
          .toList();
      for (final suggestion in selected) {
        try {
          await ref
              .read(storageServiceProvider)
              .saveManualMediaMapping(_suggestionIdentities(suggestion));
          savedCount++;
          _cachedSuggestions = _cachedSuggestions
              .where((cached) => cached.key != suggestion.key)
              .toList();
          _selectedSuggestions.remove(suggestion.key);
        } catch (error) {
          saveError = error;
          break;
        }
      }

      if (savedCount > 0) {
        await ref.read(mediaLibraryProvider.notifier).loadItems();
      }
      if (mounted) {
        final message = saveError == null
            ? AppLocalizations.of(context).mappingSaved
            : AppLocalizations.of(
                context,
              ).mappingSavedWithError(savedCount, '$saveError');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveMapping(Iterable<UnifiedMediaItem> items) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(storageServiceProvider)
          .saveManualMediaMapping(_identitiesFor(items));
      _selectedItems = {};
      await ref.read(mediaLibraryProvider.notifier).loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).mappingSaved)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeMapping(ManualMediaMapping mapping) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(storageServiceProvider).removeManualMediaMapping(mapping);
      await ref.read(mediaLibraryProvider.notifier).loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).mappingRemoved)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleSelection(UnifiedMediaItem item, List<UnifiedMediaItem> items) {
    final key = _itemKey(item);
    final selected = Set<String>.from(_selectedItems);
    if (!selected.add(key)) {
      selected.remove(key);
    } else if (selected.length > 1) {
      final other = items
          .where((candidate) => _itemKey(candidate) == selected.first)
          .firstOrNull;
      if (other != null &&
          other.services.keys
              .toSet()
              .intersection(item.services.keys.toSet())
              .isNotEmpty) {
        selected.remove(key);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).mappingRequiresDifferentServices,
            ),
          ),
        );
      }
    }
    setState(() => _selectedItems = selected);
  }

  String _serviceNames(UnifiedMediaItem item) =>
      item.services.keys.map((service) => service.shortName).join(', ');

  int? _yearFor(UnifiedMediaItem item) {
    for (final serviceItem in item.services.values) {
      final year = serviceItem.releaseYear ?? serviceItem.startDate?.year;
      if (year != null) return year;
    }
    return null;
  }

  String _suggestionTitle(SuggestedMediaMapping suggestion) =>
      suggestion.items.map((item) => item.title).toSet().join(' / ');

  Widget _suggestedMediaCard(UnifiedMediaItem item) {
    final theme = Theme.of(context);
    final year = _yearFor(item);
    return SizedBox(
      width: 220,
      child: Card(
        margin: const EdgeInsets.only(right: 10, bottom: 8),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 54,
                  height: 78,
                  child: item.posterImage.isEmpty
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            _mediaType == MediaType.anime
                                ? Icons.movie_outlined
                                : Icons.menu_book_outlined,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: item.posterImage,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _serviceNames(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (year != null)
                      Text(
                        '$year',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mappingTitle(
    ManualMediaMapping mapping,
    List<UnifiedMediaItem> library,
  ) {
    final titles = <String>{};
    for (final member in mapping.members) {
      for (final item in library) {
        final match = item.services[member.service];
        if (match?.id == member.id && item.mediaType == member.mediaType) {
          titles.add(item.title);
          break;
        }
      }
    }
    return titles.isEmpty
        ? AppLocalizations.of(context).savedMappings
        : titles.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final library = ref.watch(mediaLibraryProvider);
    final items = library.unifiedItems
        .where((item) => item.mediaType == _mediaType)
        .toList();
    final suggestionQueryKey =
        '${_mediaType.name}:${_query.trim().toLowerCase()}';
    if (_cachedSuggestionKey != suggestionQueryKey && !library.isLoading) {
      _cachedSuggestionKey = suggestionQueryKey;
      _cachedSuggestions = findSuggestedMediaMappings(items, query: _query);
      _selectedSuggestions = {};
    }
    final suggestions = _cachedSuggestionKey == suggestionQueryKey
        ? _cachedSuggestions
        : findSuggestedMediaMappings(items, query: _query);
    final savedMappings = ref
        .read(storageServiceProvider)
        .getManualMediaMappings()
        .where((mapping) => mapping.members.first.mediaType == _mediaType)
        .toList();
    final query = _query.trim().toLowerCase();
    final filteredItems = items
        .where((item) => query.isEmpty || item.matchesTitleQuery(query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(localizations.mediaMappings)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                DropdownButtonFormField<MediaType>(
                  initialValue: _mediaType,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: MediaType.anime,
                      child: Text(localizations.anime),
                    ),
                    DropdownMenuItem(
                      value: MediaType.manga,
                      child: Text(localizations.manga),
                    ),
                  ],
                  onChanged: (type) {
                    if (type == null) return;
                    setState(() {
                      _mediaType = type;
                      _selectedItems = {};
                      _selectedSuggestions = {};
                      _cachedSuggestionKey = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<_MappingMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _MappingMode.suggestions,
                        label: Text(localizations.suggestedMatches),
                        icon: const Icon(Icons.auto_awesome_outlined),
                      ),
                      ButtonSegment(
                        value: _MappingMode.manual,
                        label: Text(localizations.chooseManually),
                        icon: const Icon(Icons.search_rounded),
                      ),
                      ButtonSegment(
                        value: _MappingMode.saved,
                        label: Text(localizations.savedMappings),
                        icon: const Icon(Icons.link_rounded),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) => setState(() {
                      _mode = selection.first;
                      if (_mode != _MappingMode.manual) {
                        _selectedItems = {};
                      }
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                if (_mode != _MappingMode.saved)
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: localizations.searchMediaLibrary,
                      border: const OutlineInputBorder(),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(() => _query = ''),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                _mode != _MappingMode.saved &&
                    library.isLoading &&
                    items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : switch (_mode) {
                    _MappingMode.suggestions => _suggestionsView(
                      suggestions,
                      localizations,
                    ),
                    _MappingMode.manual => _manualView(
                      filteredItems,
                      items,
                      localizations,
                    ),
                    _MappingMode.saved => _savedView(
                      savedMappings,
                      items,
                      localizations,
                    ),
                  },
          ),
        ],
      ),
      floatingActionButton:
          _mode == _MappingMode.suggestions && _selectedSuggestions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving
                  ? null
                  : () => _saveSelectedSuggestions(suggestions),
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(localizations.mapSelectedMedia),
            )
          : _mode == _MappingMode.manual
          ? FloatingActionButton.extended(
              onPressed: _selectedItems.length == 2 && !_isSaving
                  ? () => _saveMapping(
                      items.where(
                        (item) => _selectedItems.contains(_itemKey(item)),
                      ),
                    )
                  : null,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(localizations.mapSelectedMedia),
            )
          : null,
    );
  }

  Widget _suggestionsView(
    List<SuggestedMediaMapping> suggestions,
    AppLocalizations localizations,
  ) {
    if (suggestions.isEmpty) {
      return Center(child: Text(localizations.noSuggestedMatches));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Text(
            localizations.possibleMatchHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final suggestion in suggestions)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  value: _selectedSuggestions.contains(suggestion.key),
                  onChanged: _isSaving
                      ? null
                      : (_) => _toggleSuggestion(suggestion),
                  title: Text(
                    _suggestionTitle(suggestion),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    localizations.mappingMediaCount(suggestion.items.length),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                SizedBox(
                  height: 112,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final item in suggestion.items)
                        _suggestedMediaCard(item),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _manualView(
    List<UnifiedMediaItem> visibleItems,
    List<UnifiedMediaItem> allItems,
    AppLocalizations localizations,
  ) {
    if (visibleItems.isEmpty) {
      return Center(child: Text(localizations.noMediaInLibrary));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      children: [
        for (final item in visibleItems)
          CheckboxListTile(
            value: _selectedItems.contains(_itemKey(item)),
            onChanged:
                _isSaving ||
                    (_selectedItems.length == 2 &&
                        !_selectedItems.contains(_itemKey(item)))
                ? null
                : (_) => _toggleSelection(item, allItems),
            title: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_serviceNames(item)),
            secondary: _mediaType == MediaType.anime
                ? const Icon(Icons.movie_outlined)
                : const Icon(Icons.menu_book_outlined),
          ),
      ],
    );
  }

  Widget _savedView(
    List<ManualMediaMapping> mappings,
    List<UnifiedMediaItem> items,
    AppLocalizations localizations,
  ) {
    if (mappings.isEmpty) {
      return Center(child: Text(localizations.noSavedMappings));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final mapping in mappings)
          Card(
            child: ListTile(
              title: Text(_mappingTitle(mapping, items)),
              subtitle: Text(
                mapping.members
                    .map(
                      (member) => '${member.service.shortName} #${member.id}',
                    )
                    .join(' · '),
              ),
              trailing: IconButton(
                tooltip: localizations.removeMapping,
                onPressed: _isSaving ? null : () => _removeMapping(mapping),
                icon: const Icon(Icons.link_off_rounded),
              ),
            ),
          ),
      ],
    );
  }
}
