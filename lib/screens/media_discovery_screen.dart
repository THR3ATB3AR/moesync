import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_discovery.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/widgets/media/media_grid_card.dart';

class MediaDiscoveryScreen extends ConsumerStatefulWidget {
  const MediaDiscoveryScreen({required this.initialQuery, super.key});

  final MediaDiscoveryQuery initialQuery;

  @override
  ConsumerState<MediaDiscoveryScreen> createState() =>
      _MediaDiscoveryScreenState();
}

class _MediaDiscoveryScreenState extends ConsumerState<MediaDiscoveryScreen> {
  late AnimeSeason _season;
  late int _year;
  late MediaDiscoveryQuery _query;

  bool get _isSeasonal =>
      _query.category == MediaDiscoveryCategory.currentSeason ||
      _query.category == MediaDiscoveryCategory.nextSeason;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _query = widget.initialQuery.copyWith(includeOtherServices: true);
    final currentSeason = AnimeSeason.forDate(now);
    final isNextSeason = _query.category == MediaDiscoveryCategory.nextSeason;
    _season =
        _query.season ?? (isNextSeason ? currentSeason.next : currentSeason);
    _year =
        _query.year ??
        (isNextSeason && currentSeason == AnimeSeason.fall
            ? now.year + 1
            : now.year);
    if (_isSeasonal && (_query.season == null || _query.year == null)) {
      _query = _query.copyWith(season: _season, year: _year);
    }
  }

  String _seasonLabel(AppLocalizations localizations, AnimeSeason season) =>
      switch (season) {
        AnimeSeason.winter => localizations.seasonWinter,
        AnimeSeason.spring => localizations.seasonSpring,
        AnimeSeason.summer => localizations.seasonSummer,
        AnimeSeason.fall => localizations.seasonFall,
      };

  String _title(AppLocalizations localizations) => switch (_query.category) {
    MediaDiscoveryCategory.currentSeason || MediaDiscoveryCategory.nextSeason =>
      '${_seasonLabel(localizations, _season)} $_year',
    MediaDiscoveryCategory.recommended => localizations.recommended,
    MediaDiscoveryCategory.trending => localizations.trending,
    MediaDiscoveryCategory.mostPopular => localizations.mostPopular,
    MediaDiscoveryCategory.newlyAdded => localizations.newlyAdded,
  };

  Future<void> _showSeasonSettings() async {
    final localizations = AppLocalizations.of(context);
    var selectedSeason = _season;
    var selectedYear = _year;
    int? selectedOffset;
    final now = DateTime.now();
    final currentSeason = AnimeSeason.forDate(now);
    final currentYear = now.year;
    for (final offset in [-1, 0, 1]) {
      final index = currentSeason.index + offset;
      final candidateSeason = AnimeSeason.values[(index % 4 + 4) % 4];
      final candidateYear =
          currentYear +
          (index < 0
              ? -1
              : index >= 4
              ? 1
              : 0);
      if (candidateSeason == selectedSeason && candidateYear == selectedYear) {
        selectedOffset = offset;
      }
    }
    final result = await showModalBottomSheet<MediaDiscoveryQuery>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations.seasonAndYear,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: -1,
                      label: Text(localizations.previous),
                    ),
                    ButtonSegment(value: 0, label: Text(localizations.current)),
                    ButtonSegment(value: 1, label: Text(localizations.next)),
                  ],
                  selected: selectedOffset == null ? {} : {selectedOffset!},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) {
                      setSheetState(() => selectedOffset = null);
                      return;
                    }
                    final offset = selection.first;
                    final baseIndex = currentSeason.index + offset;
                    setSheetState(() {
                      selectedOffset = offset;
                      selectedSeason =
                          AnimeSeason.values[(baseIndex % 4 + 4) % 4];
                      selectedYear = currentYear + (baseIndex < 0 ? -1 : 0);
                      if (baseIndex >= 4) selectedYear = currentYear + 1;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AnimeSeason>(
                  key: ValueKey(selectedSeason),
                  initialValue: selectedSeason,
                  decoration: InputDecoration(labelText: localizations.season),
                  items: AnimeSeason.values
                      .map(
                        (season) => DropdownMenuItem(
                          value: season,
                          child: Text(_seasonLabel(localizations, season)),
                        ),
                      )
                      .toList(),
                  onChanged: (season) {
                    if (season != null) {
                      setSheetState(() {
                        selectedSeason = season;
                        selectedOffset = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(selectedYear),
                  initialValue: selectedYear,
                  decoration: InputDecoration(labelText: localizations.year),
                  items: [
                    for (var year = currentYear + 5; year >= 1980; year--)
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: (year) {
                    if (year != null) {
                      setSheetState(() {
                        selectedYear = year;
                        selectedOffset = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    MediaDiscoveryQuery(
                      category: _query.category,
                      mediaType: _query.mediaType,
                      season: selectedSeason,
                      year: selectedYear,
                      includeOtherServices: true,
                    ),
                  ),
                  child: Text(localizations.apply),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _query = result;
        _season = result.season!;
        _year = result.year!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final results = ref.watch(mediaDiscoveryProvider(_query));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_title(localizations))),
      body: Column(
        children: [
          if (!_isSeasonal)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SegmentedButton<MediaType>(
                segments: [
                  ButtonSegment(
                    value: MediaType.anime,
                    icon: const Icon(Icons.movie_filter_outlined),
                    label: Text(localizations.anime),
                  ),
                  ButtonSegment(
                    value: MediaType.manga,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(localizations.manga),
                  ),
                ],
                selected: {_query.mediaType},
                onSelectionChanged: (selection) => setState(
                  () => _query = _query.copyWith(mediaType: selection.first),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(mediaDiscoveryProvider(_query));
                await ref.read(mediaDiscoveryProvider(_query).future);
              },
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.65,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 44,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations.failedToLoadMedia,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => ref.invalidate(
                                  mediaDiscoveryProvider(_query),
                                ),
                                child: Text(localizations.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                data: (items) {
                  final unifiedItems = unifyDiscoveryItems(items);
                  if (unifiedItems.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.65,
                          child: Center(
                            child: Text(localizations.noSearchResults),
                          ),
                        ),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                    itemCount: unifiedItems.length,
                    itemBuilder: (context, index) => MediaGridCard(
                      item: unifiedItems[index],
                      type: _query.mediaType,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSeasonal
          ? FloatingActionButton.extended(
              onPressed: _showSeasonSettings,
              icon: const Icon(Icons.tune_rounded),
              label: Text('${_seasonLabel(localizations, _season)} $_year'),
            )
          : null,
    );
  }
}
