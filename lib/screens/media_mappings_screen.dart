import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Set<String> _titleKeys(UnifiedMediaItem item) {
    final titles = <String>[
      item.title,
      for (final service in item.services.values) ...[
        service.title,
        if (service.englishTitle != null) service.englishTitle!,
        if (service.japaneseTitle != null) service.japaneseTitle!,
        if (service.romajiTitle != null) service.romajiTitle!,
        ...service.alternativeTitles,
      ],
    ];
    return titles
        .map(
          (title) => title.toLowerCase().replaceAll(
            RegExp(r'[\s\-_.,:;!?()\[\]{}「」『』]+'),
            '',
          ),
        )
        .where((title) => title.length >= 3)
        .toSet();
  }

  List<({UnifiedMediaItem first, UnifiedMediaItem second, String title})>
  _findSuggestions(List<UnifiedMediaItem> items) {
    final byTitle = <String, List<UnifiedMediaItem>>{};
    final pairs =
        <
          String,
          ({UnifiedMediaItem first, UnifiedMediaItem second, String title})
        >{};
    final query = _query.trim().toLowerCase();
    for (final item in items) {
      for (final title in _titleKeys(item)) {
        for (final other in byTitle[title] ?? const <UnifiedMediaItem>[]) {
          if (other.services.keys
              .toSet()
              .intersection(item.services.keys.toSet())
              .isNotEmpty) {
            continue;
          }
          final first = other;
          final second = item;
          if (query.isNotEmpty &&
              !title.toLowerCase().contains(query) &&
              !first.matchesTitleQuery(query) &&
              !second.matchesTitleQuery(query)) {
            continue;
          }
          final pairKeys = [_itemKey(first), _itemKey(second)]..sort();
          pairs.putIfAbsent(
            pairKeys.join('::'),
            () => (first: first, second: second, title: title),
          );
          if (pairs.length >= 100) return pairs.values.toList();
        }
        byTitle.putIfAbsent(title, () => []).add(item);
      }
    }

    return pairs.values.toList();
  }

  List<MediaMappingIdentity> _identitiesFor(Iterable<UnifiedMediaItem> items) =>
      [
        for (final item in items)
          for (final serviceItem in item.services.values)
            MediaMappingIdentity.fromItem(serviceItem),
      ];

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
    final suggestions = _findSuggestions(items);
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
      floatingActionButton: _mode == _MappingMode.manual
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
    List<({UnifiedMediaItem first, UnifiedMediaItem second, String title})>
    suggestions,
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
            child: ListTile(
              title: Text(
                '${suggestion.first.title} / ${suggestion.second.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_serviceNames(suggestion.first)} · ${_serviceNames(suggestion.second)}',
              ),
              trailing: IconButton(
                tooltip: localizations.mapSelectedMedia,
                onPressed: _isSaving
                    ? null
                    : () => _saveMapping([suggestion.first, suggestion.second]),
                icon: const Icon(Icons.link_rounded),
              ),
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
