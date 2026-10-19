import 'package:moesync/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'media_item.dart';

class MediaVoiceActorItem {
  final int id;
  final String name;
  final String? nativeName;
  final String language;
  final String? imageUrl;
  final String? roleNotes;

  const MediaVoiceActorItem({
    required this.id,
    required this.name,
    this.nativeName,
    required this.language,
    this.imageUrl,
    this.roleNotes,
  });
}

class MediaCharacterItem {
  final int id;
  final int? malId;
  final String name;
  final String? nativeName;
  final List<String> alternativeNames;
  final String role;
  final String? imageUrl;
  final String? description;
  final String? gender;
  final String? age;
  final String? dateOfBirth;
  final String? bloodType;
  final List<MediaVoiceActorItem> voiceActors;

  const MediaCharacterItem({
    this.id = 0,
    this.malId,
    required this.name,
    this.nativeName,
    this.alternativeNames = const [],
    required this.role,
    this.imageUrl,
    this.description,
    this.gender,
    this.age,
    this.dateOfBirth,
    this.bloodType,
    this.voiceActors = const [],
  });

  List<MediaVoiceActorItem> get sortedVoiceActors =>
      sortVoiceActors(voiceActors);
}

class MediaStaffItem {
  final int id;
  final int? malId;
  final String name;
  final String? nativeName;
  final String role;
  final String? imageUrl;

  const MediaStaffItem({
    this.id = 0,
    this.malId,
    required this.name,
    this.nativeName,
    required this.role,
    this.imageUrl,
  });
}

class VoiceActorCharacterRole {
  final int characterId;
  final int? characterMalId;
  final String characterName;
  final String? characterImageUrl;
  final int mediaId;
  final int? mediaMalId;
  final String mediaTitle;
  final MediaType mediaType;
  final String? mediaPosterImage;
  final String? role;

  const VoiceActorCharacterRole({
    required this.characterId,
    this.characterMalId,
    required this.characterName,
    this.characterImageUrl,
    required this.mediaId,
    this.mediaMalId,
    required this.mediaTitle,
    this.mediaType = MediaType.anime,
    this.mediaPosterImage,
    this.role,
  });
}

class VoiceActorMediaRole {
  final int mediaId;
  final int? mediaMalId;
  final String mediaTitle;
  final MediaType mediaType;
  final String? mediaPosterImage;
  final String role;

  const VoiceActorMediaRole({
    required this.mediaId,
    this.mediaMalId,
    required this.mediaTitle,
    this.mediaType = MediaType.anime,
    this.mediaPosterImage,
    required this.role,
  });
}

class StaffDetailData {
  final int id;
  final int? malId;
  final String name;
  final String? nativeName;
  final List<String> alternativeNames;
  final String? imageUrl;
  final String? description;
  final String? birthday;
  final String? deathday;
  final int? age;
  final String? gender;
  final String? bloodType;
  final String? yearsActive;
  final String? homeTown;
  final List<String> occupations;
  final List<String> websiteUrls;
  final List<VoiceActorCharacterRole> characterRoles;
  final List<VoiceActorMediaRole> mediaRoles;

  const StaffDetailData({
    required this.id,
    this.malId,
    required this.name,
    this.nativeName,
    this.alternativeNames = const [],
    this.imageUrl,
    this.description,
    this.birthday,
    this.deathday,
    this.age,
    this.gender,
    this.bloodType,
    this.yearsActive,
    this.homeTown,
    this.occupations = const [],
    this.websiteUrls = const [],
    this.characterRoles = const [],
    this.mediaRoles = const [],
  });
}

class CharacterMediaAppearance {
  final int mediaId;
  final int? mediaMalId;
  final String mediaTitle;
  final MediaType mediaType;
  final String? mediaPosterImage;
  final String role;

  const CharacterMediaAppearance({
    required this.mediaId,
    this.mediaMalId,
    required this.mediaTitle,
    this.mediaType = MediaType.anime,
    this.mediaPosterImage,
    required this.role,
  });
}

class CharacterDetailData {
  final int id;
  final int? malId;
  final String name;
  final String? nativeName;
  final List<String> alternativeNames;
  final String? imageUrl;
  final String? description;
  final String? gender;
  final String? age;
  final String? dateOfBirth;
  final String? bloodType;
  final List<CharacterMediaAppearance> mediaAppearances;
  final List<MediaVoiceActorItem> voiceActors;

  const CharacterDetailData({
    required this.id,
    this.malId,
    required this.name,
    this.nativeName,
    this.alternativeNames = const [],
    this.imageUrl,
    this.description,
    this.gender,
    this.age,
    this.dateOfBirth,
    this.bloodType,
    this.mediaAppearances = const [],
    this.voiceActors = const [],
  });

  List<MediaVoiceActorItem> get sortedVoiceActors =>
      sortVoiceActors(voiceActors);
}

class MediaRankingItem {
  final int rank;
  final String context;
  final bool isStar;

  const MediaRankingItem({
    required this.rank,
    required this.context,
    required this.isStar,
  });
}

class MediaRelationItem {
  final int id;
  final int? malId;
  final String title;
  final String relationType;
  final String? format;
  final String? posterImage;
  final MediaType mediaType;
  final ServiceType sourceService;

  const MediaRelationItem({
    required this.id,
    this.malId,
    required this.title,
    required this.relationType,
    this.format,
    this.posterImage,
    this.mediaType = MediaType.anime,
    this.sourceService = ServiceType.mal,
  });
}

class MediaRecommendationItem {
  final int id;
  final int? malId;
  final String title;
  final String? posterImage;
  final String? format;
  final MediaType mediaType;
  final ServiceType sourceService;

  const MediaRecommendationItem({
    required this.id,
    this.malId,
    required this.title,
    this.posterImage,
    this.format,
    this.mediaType = MediaType.anime,
    this.sourceService = ServiceType.mal,
  });
}

class ThemeItem {
  final int id;
  final int animeId;
  final String text;

  const ThemeItem({
    required this.id,
    required this.animeId,
    required this.text,
  });
}

class MediaDetailData {
  final ServiceType sourceService;
  final int serviceId;
  final int malId;
  final String title;
  final String? romajiTitle;
  final String? englishTitle;
  final String? nativeTitle;
  final List<String> synonyms;
  final String posterImage;
  final String? bannerImage;
  final String? format;
  final int? year;
  final String? status;
  final int? episodes;
  final int? chapters;
  final int? volumes;
  final String? duration;
  final double? score;
  final List<String> genres;
  final List<String> tags;
  final String? description;
  final int? rank;
  final int? popularity;
  final int? favorites;
  final int? trending;
  final String? startDate;
  final String? endDate;
  final String? season;
  final String? broadcast;
  final String? source;
  final List<String> studios;
  final List<MediaCharacterItem> characters;
  final List<MediaStaffItem> staff;
  final List<MediaRankingItem> rankings;
  final Map<String, int> statusDistribution;
  final Map<int, int> scoreDistribution;
  final List<ThemeItem> openingThemes;
  final List<ThemeItem> endingThemes;
  final List<MediaRelationItem> relations;
  final List<MediaRecommendationItem> recommendations;

  const MediaDetailData({
    required this.sourceService,
    required this.serviceId,
    required this.malId,
    required this.title,
    this.romajiTitle,
    this.englishTitle,
    this.nativeTitle,
    this.synonyms = const [],
    required this.posterImage,
    this.bannerImage,
    this.format,
    this.year,
    this.status,
    this.episodes,
    this.chapters,
    this.volumes,
    this.duration,
    this.score,
    this.genres = const [],
    this.tags = const [],
    this.description,
    this.rank,
    this.popularity,
    this.favorites,
    this.trending,
    this.startDate,
    this.endDate,
    this.season,
    this.broadcast,
    this.source,
    this.studios = const [],
    this.characters = const [],
    this.staff = const [],
    this.rankings = const [],
    this.statusDistribution = const {},
    this.scoreDistribution = const {},
    this.openingThemes = const [],
    this.endingThemes = const [],
    this.relations = const [],
    this.recommendations = const [],
  });

  List<MediaCharacterItem> get sortedCharacters => sortCharacters(characters);
  List<MediaStaffItem> get sortedStaff => sortStaff(staff);

  String titleFor(TitleLanguage language) {
    final preferred = switch (language) {
      TitleLanguage.source => title,
      TitleLanguage.english => englishTitle,
      TitleLanguage.japanese => nativeTitle,
      TitleLanguage.romaji => romajiTitle,
    };
    return preferred?.trim().isNotEmpty == true ? preferred! : title;
  }
}

List<T> stableSort<T>(List<T> items, int Function(T a, T b) compare) {
  final indexed = items.asMap().entries.toList();
  indexed.sort((a, b) {
    final cmp = compare(a.value, b.value);
    if (cmp != 0) return cmp;
    return a.key.compareTo(b.key);
  });
  return indexed.map((e) => e.value).toList();
}

int getVoiceActorLanguagePriority(String language) {
  final l = language.toLowerCase().trim();
  if (l == 'japanese' || l == 'ja' || l.contains('japan')) {
    return 1;
  }
  if (l == 'english' || l == 'en' || l.contains('eng')) {
    return 2;
  }
  return 3;
}

List<MediaVoiceActorItem> sortVoiceActors(List<MediaVoiceActorItem> vas) {
  return stableSort(vas, (a, b) {
    final prioA = getVoiceActorLanguagePriority(a.language);
    final prioB = getVoiceActorLanguagePriority(b.language);
    return prioA.compareTo(prioB);
  });
}

int getCharacterRolePriority(String role) {
  final r = role.toLowerCase().trim();
  if (r.contains('main')) {
    return 1;
  }
  if (r.contains('supporting')) {
    return 2;
  }
  return 3;
}

List<MediaCharacterItem> sortCharacters(List<MediaCharacterItem> chars) {
  return stableSort(chars, (a, b) {
    final prioA = getCharacterRolePriority(a.role);
    final prioB = getCharacterRolePriority(b.role);
    return prioA.compareTo(prioB);
  });
}

int getStaffRolePriority(String role) {
  final r = role.toLowerCase().trim();

  if (r == 'director' ||
      r.contains('chief director') ||
      r.contains('series director')) {
    return 1;
  }
  if (r.contains('director') &&
      !r.contains('art') &&
      !r.contains('sound') &&
      !r.contains('animat') &&
      !r.contains('photo') &&
      !r.contains('episode') &&
      !r.contains('assistant') &&
      !r.contains('casting')) {
    return 1;
  }

  if (r.contains('original creator') ||
      r.contains('original story') ||
      r.contains('original concept') ||
      r.contains('author') ||
      r.contains('manga') ||
      r.contains('story & art')) {
    return 2;
  }

  if (r.contains('series composition') ||
      r.contains('screenplay') ||
      r.contains('script')) {
    return 3;
  }

  if (r.contains('character design') ||
      r.contains('original character design')) {
    return 4;
  }

  if (r.contains('chief animation director') || r.contains('art director')) {
    return 5;
  }

  if (r.contains('music') || r.contains('sound director')) {
    return 6;
  }

  if (r.contains('producer')) {
    return 7;
  }

  if (r.contains('director')) {
    return 8;
  }
  if (r.contains('design') ||
      r.contains('photo') ||
      r.contains('color') ||
      r.contains('editing')) {
    return 9;
  }

  return 100;
}

List<MediaStaffItem> sortStaff(List<MediaStaffItem> staff) {
  return stableSort(staff, (a, b) {
    final prioA = getStaffRolePriority(a.role);
    final prioB = getStaffRolePriority(b.role);
    return prioA.compareTo(prioB);
  });
}

enum StaffCastType { staff, character }

UnifiedMediaItem resolveMediaItem({
  required int id,
  int? malId,
  required String title,
  String? posterImage,
  required MediaType mediaType,
  required WidgetRef ref,
}) {
  final library = ref.read(mediaLibraryProvider);
  return library.unifiedItems.firstWhere(
    (u) =>
        (malId != null && malId > 0 && u.malId == malId) ||
        (id > 0 && u.malId == id) ||
        u.title.toLowerCase() == title.toLowerCase(),
    orElse: () => UnifiedMediaItem(
      malId: (malId != null && malId > 0) ? malId : id,
      title: title,
      mediaType: mediaType,
      posterImage: posterImage ?? '',
      services: {
        ServiceType.anilist: MediaItem(
          id: id,
          malId: malId,
          title: title,
          service: ServiceType.anilist,
          status: mediaType == MediaType.anime
              ? 'plan_to_watch'
              : 'plan_to_read',
          progress: 0,
          score: 0,
          posterImage: posterImage ?? '',
          mediaType: mediaType,
        ),
      },
    ),
  );
}

String formatNumber(int number) {
  final str = number.toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write(' ');
    }
  }
  return buffer.toString().split('').reversed.join('');
}

String formatShortNumber(int number) {
  if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}k';
  }
  return '$number';
}

UnifiedMediaItem resolveUnifiedItem({
  required int id,
  int? malId,
  required String title,
  String? posterImage,
  required MediaType mediaType,
  required ServiceType sourceService,
  required WidgetRef ref,
}) {
  final library = ref.read(mediaLibraryProvider);
  final match = library.unifiedItems.firstWhere(
    (u) =>
        (malId != null && malId > 0 && u.malId == malId) ||
        (id > 0 && u.malId == id) ||
        u.title.toLowerCase() == title.toLowerCase(),
    orElse: () => UnifiedMediaItem(
      malId: (malId != null && malId > 0)
          ? malId
          : (sourceService == ServiceType.mal ? id : 0),
      title: title,
      mediaType: mediaType,
      posterImage: posterImage ?? '',
      services: {
        sourceService: MediaItem(
          id: id,
          malId: malId,
          title: title,
          service: sourceService,
          status: mediaType == MediaType.anime
              ? 'plan_to_watch'
              : 'plan_to_read',
          progress: 0,
          totalProgress: null,
          score: 0,
          posterImage: posterImage ?? '',
          mediaType: mediaType,
        ),
      },
    ),
  );
  return match;
}
