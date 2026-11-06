import 'media_item.dart';

enum MediaDiscoveryCategory {
  currentSeason,
  nextSeason,
  recommended,
  trending,
  mostPopular,
  newlyAdded,
}

enum AnimeSeason {
  winter,
  spring,
  summer,
  fall;

  String get apiValue => switch (this) {
    AnimeSeason.winter => 'WINTER',
    AnimeSeason.spring => 'SPRING',
    AnimeSeason.summer => 'SUMMER',
    AnimeSeason.fall => 'FALL',
  };

  static AnimeSeason forDate(DateTime date) => switch (date.month) {
    1 || 2 || 3 => AnimeSeason.winter,
    4 || 5 || 6 => AnimeSeason.spring,
    7 || 8 || 9 => AnimeSeason.summer,
    _ => AnimeSeason.fall,
  };

  AnimeSeason get next => AnimeSeason.values[(index + 1) % values.length];

  AnimeSeason get previous =>
      AnimeSeason.values[(index - 1 + values.length) % values.length];
}

const mediaDiscoveryPageSize = 30;

class MediaDiscoveryPageRequest {
  const MediaDiscoveryPageRequest({required this.query, required this.page});

  final MediaDiscoveryQuery query;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is MediaDiscoveryPageRequest &&
      other.query == query &&
      other.page == page;

  @override
  int get hashCode => Object.hash(query, page);
}

class MediaDiscoveryPage {
  const MediaDiscoveryPage({required this.items, required this.hasMore});

  final List<MediaItem> items;
  final bool hasMore;
}

class MediaDiscoveryQuery {
  const MediaDiscoveryQuery({
    required this.category,
    this.mediaType = MediaType.anime,
    this.season,
    this.year,
    this.includeOtherServices = false,
  });

  final MediaDiscoveryCategory category;
  final MediaType mediaType;
  final AnimeSeason? season;
  final int? year;
  final bool includeOtherServices;

  MediaDiscoveryQuery copyWith({
    MediaType? mediaType,
    AnimeSeason? season,
    int? year,
    bool? includeOtherServices,
  }) => MediaDiscoveryQuery(
    category: category,
    mediaType: mediaType ?? this.mediaType,
    season: season ?? this.season,
    year: year ?? this.year,
    includeOtherServices: includeOtherServices ?? this.includeOtherServices,
  );

  @override
  bool operator ==(Object other) =>
      other is MediaDiscoveryQuery &&
      other.category == category &&
      other.mediaType == mediaType &&
      other.season == season &&
      other.year == year &&
      other.includeOtherServices == includeOtherServices;

  @override
  int get hashCode =>
      Object.hash(category, mediaType, season, year, includeOtherServices);
}

List<UnifiedMediaItem> unifyDiscoveryItems(Iterable<MediaItem> items) {
  final merged = <String, UnifiedMediaItem>{};
  for (final item in items) {
    final malId =
        item.malId ?? (item.service == ServiceType.mal ? item.id : null);
    final key = malId != null && malId > 0
        ? 'mal:$malId'
        : '${item.service.name}:${item.id}';
    var existingKey = key;
    var existing = merged[key];
    if (existing == null) {
      final itemTitles = {
        item.title,
        item.englishTitle ?? '',
        item.japaneseTitle ?? '',
        item.romajiTitle ?? '',
        ...item.alternativeTitles,
      }.map((title) => title.trim().toLowerCase()).toSet()..remove('');
      final matchingEntry = merged.entries.where((entry) {
        final candidate = entry.value;
        if (candidate.mediaType != item.mediaType) return false;
        if (malId != null &&
            malId > 0 &&
            candidate.malId > 0 &&
            candidate.malId != malId) {
          return false;
        }
        final candidateTitles = {
          candidate.title,
          ...candidate.services.values.expand(
            (service) => [
              service.title,
              service.englishTitle ?? '',
              service.japaneseTitle ?? '',
              service.romajiTitle ?? '',
              ...service.alternativeTitles,
            ],
          ),
        }.map((title) => title.trim().toLowerCase()).toSet()..remove('');
        return !itemTitles.contains('unknown') &&
            itemTitles.intersection(candidateTitles).isNotEmpty;
      }).firstOrNull;
      if (matchingEntry != null) {
        existingKey = matchingEntry.key;
        existing = matchingEntry.value;
      }
    }
    if (existing == null) {
      merged[key] = UnifiedMediaItem(
        malId: malId ?? 0,
        title: item.title,
        posterImage: item.posterImage,
        mediaType: item.mediaType,
        services: {item.service: item},
      );
      continue;
    }

    merged.remove(existingKey);
    final mergedItem = existing.copyWith(
      malId: malId != null && malId > 0 ? malId : existing.malId,
      title: existing.title.isNotEmpty ? existing.title : item.title,
      posterImage: existing.posterImage.isNotEmpty
          ? existing.posterImage
          : item.posterImage,
      services: {...existing.services, item.service: item},
    );
    merged[mergedItem.malId > 0 ? 'mal:${mergedItem.malId}' : existingKey] =
        mergedItem;
  }
  return merged.values.toList();
}
