import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

enum MediaType { anime, manga }

enum TitleLanguage { source, english, japanese, romaji }

enum MediaViewMode { grid, list }

enum ServiceDisplayStyle { text, icon, monoIcon }

enum MusicService {
  spotify('Spotify', 'Spotify'),
  appleMusic('Apple Music', 'Apple Music'),
  youtubeMusic('YouTube Music', 'YouTube Music');

  final String displayName;
  final String shortName;
  const MusicService(this.displayName, this.shortName);

  String get iconAsset {
    switch (this) {
      case MusicService.spotify:
        return 'assets/spotify.svg';
      case MusicService.appleMusic:
        return 'assets/apple-music.svg';
      case MusicService.youtubeMusic:
        return 'assets/youtube-music.svg';
    }
  }

  String get monoIconAsset {
    switch (this) {
      case MusicService.spotify:
        return 'assets/spotify-mono.svg';
      case MusicService.appleMusic:
        return 'assets/apple-music-mono.svg';
      case MusicService.youtubeMusic:
        return 'assets/youtube-music-mono.svg';
    }
  }

  static MusicService? fromString(String str) {
    final lower = str.toLowerCase();
    for (final s in MusicService.values) {
      if (s.name.toLowerCase() == lower ||
          s.shortName.toLowerCase() == lower ||
          s.displayName.toLowerCase() == lower) {
        return s;
      }
    }
    return null;
  }
}

enum ServiceType {
  mal('MyAnimeList', 'MAL'),
  anilist('AniList', 'AniList'),
  kitsu('Kitsu', 'Kitsu'),
  shikimori('Shikimori', 'Shikimori'),
  simkl('Simkl', 'Simkl'),
  mangabaka('MangaBaka', 'MangaBaka'),
  mangaupdates('MangaUpdates', 'MU');

  final String displayName;
  final String shortName;
  const ServiceType(this.displayName, this.shortName);

  String get iconAsset {
    switch (this) {
      case ServiceType.mal:
        return 'assets/myanimelist.svg';
      case ServiceType.anilist:
        return 'assets/anilist.svg';
      case ServiceType.kitsu:
        return 'assets/kitsu.svg';
      case ServiceType.shikimori:
        return 'assets/shikimori.svg';
      case ServiceType.simkl:
        return 'assets/simkl.svg';
      case ServiceType.mangabaka:
        return 'assets/mangabaka.svg';
      case ServiceType.mangaupdates:
        return 'assets/mangaupdates.svg';
    }
  }

  String get monoIconAsset {
    switch (this) {
      case ServiceType.mal:
        return 'assets/myanimelist-mono.svg';
      case ServiceType.anilist:
        return 'assets/anilist-mono.svg';
      case ServiceType.kitsu:
        return 'assets/kitsu-mono.svg';
      case ServiceType.shikimori:
        return 'assets/shikimori-mono.svg';
      case ServiceType.simkl:
        return 'assets/simkl-mono.svg';
      case ServiceType.mangabaka:
        return 'assets/mangabaka-mono.svg';
      case ServiceType.mangaupdates:
        return 'assets/mangaupdates-mono.svg';
    }
  }

  bool supportsMediaType(MediaType type) {
    if (type == MediaType.anime) {
      return this != ServiceType.mangabaka && this != ServiceType.mangaupdates;
    } else {
      return this != ServiceType.simkl;
    }
  }

  static List<ServiceType> forMediaType(MediaType type) {
    return ServiceType.values.where((s) => s.supportsMediaType(type)).toList();
  }

  static ServiceType? fromString(String str) {
    final lower = str.toLowerCase();
    for (final s in ServiceType.values) {
      if (s.name.toLowerCase() == lower ||
          s.shortName.toLowerCase() == lower ||
          s.displayName.toLowerCase() == lower) {
        return s;
      }
    }
    return null;
  }
}

enum MediaSortField {
  title,
  score,
  progress,
  updatedAt,
  createdAt,
  startDate,
  finishDate,
  repeats,
  priority;

  String getLabel(BuildContext context) {
    switch (this) {
      case MediaSortField.title:
        return AppLocalizations.of(context).title;
      case MediaSortField.score:
        return AppLocalizations.of(context).score;
      case MediaSortField.progress:
        return AppLocalizations.of(context).progress;
      case MediaSortField.updatedAt:
        return AppLocalizations.of(context).updatedAt;
      case MediaSortField.createdAt:
        return AppLocalizations.of(context).createdAt;
      case MediaSortField.startDate:
        return AppLocalizations.of(context).startDate;
      case MediaSortField.finishDate:
        return AppLocalizations.of(context).finishDate;
      case MediaSortField.repeats:
        return AppLocalizations.of(context).repeats;
      case MediaSortField.priority:
        return AppLocalizations.of(context).priority;
    }
  }
}

enum SortDirection { ascending, descending }

class MediaItem {
  final int id;
  final int? listEntryId;
  final int? malId;
  final String title;
  final String? englishTitle;
  final String? japaneseTitle;
  final String? romajiTitle;
  final List<String> alternativeTitles;
  final String status;
  final int score;
  final int progress;
  final int? totalProgress;
  final String posterImage;
  final ServiceType service;
  final MediaType mediaType;
  final String? originalStatus;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? startDate;
  final DateTime? finishDate;
  final int repeatCount;
  final int priority;

  const MediaItem({
    required this.id,
    this.listEntryId,
    this.malId,
    required this.title,
    this.englishTitle,
    this.japaneseTitle,
    this.romajiTitle,
    this.alternativeTitles = const [],
    required this.status,
    required this.score,
    required this.progress,
    this.totalProgress,
    required this.posterImage,
    required this.service,
    this.mediaType = MediaType.anime,
    this.originalStatus,
    this.updatedAt,
    this.createdAt,
    this.startDate,
    this.finishDate,
    this.repeatCount = 0,
    this.priority = 0,
  });

  MediaItem copyWith({
    int? id,
    int? listEntryId,
    int? malId,
    String? title,
    String? englishTitle,
    String? japaneseTitle,
    String? romajiTitle,
    List<String>? alternativeTitles,
    String? status,
    int? score,
    int? progress,
    int? totalProgress,
    String? posterImage,
    ServiceType? service,
    MediaType? mediaType,
    String? originalStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? finishDate,
    int? repeatCount,
    int? priority,
  }) {
    return MediaItem(
      id: id ?? this.id,
      listEntryId: listEntryId ?? this.listEntryId,
      malId: malId ?? this.malId,
      title: title ?? this.title,
      englishTitle: englishTitle ?? this.englishTitle,
      japaneseTitle: japaneseTitle ?? this.japaneseTitle,
      romajiTitle: romajiTitle ?? this.romajiTitle,
      alternativeTitles: alternativeTitles ?? this.alternativeTitles,
      status: status ?? this.status,
      score: score ?? this.score,
      progress: progress ?? this.progress,
      totalProgress: totalProgress ?? this.totalProgress,
      posterImage: posterImage ?? this.posterImage,
      service: service ?? this.service,
      mediaType: mediaType ?? this.mediaType,
      originalStatus: originalStatus ?? this.originalStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
      repeatCount: repeatCount ?? this.repeatCount,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'listEntryId': listEntryId,
    'malId': malId,
    'title': title,
    'englishTitle': englishTitle,
    'japaneseTitle': japaneseTitle,
    'romajiTitle': romajiTitle,
    'alternativeTitles': alternativeTitles,
    'status': status,
    'score': score,
    'progress': progress,
    'totalProgress': totalProgress,
    'posterImage': posterImage,
    'service': service.name,
    'mediaType': mediaType.name,
    'originalStatus': originalStatus,
    'updatedAt': updatedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'finishDate': finishDate?.toIso8601String(),
    'repeatCount': repeatCount,
    'priority': priority,
  };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
    id: json['id'] as int,
    listEntryId: (json['listEntryId'] as num?)?.toInt(),
    malId: (json['malId'] as num?)?.toInt(),
    title: json['title'] as String? ?? 'Unknown',
    englishTitle: json['englishTitle'] as String?,
    japaneseTitle: json['japaneseTitle'] as String?,
    romajiTitle: json['romajiTitle'] as String?,
    alternativeTitles:
        (json['alternativeTitles'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const [],
    status: json['status'] as String? ?? 'plan_to_watch',
    score: (json['score'] as num?)?.toInt() ?? 0,
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    totalProgress: (json['totalProgress'] as num?)?.toInt(),
    posterImage: json['posterImage'] as String? ?? '',
    service: ServiceType.values.firstWhere(
      (s) => s.name == json['service'],
      orElse: () => ServiceType.mal,
    ),
    mediaType: MediaType.values.firstWhere(
      (m) => m.name == json['mediaType'],
      orElse: () => MediaType.anime,
    ),
    originalStatus: json['originalStatus'] as String?,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
    startDate: json['startDate'] != null
        ? DateTime.tryParse(json['startDate'] as String)
        : null,
    finishDate: json['finishDate'] != null
        ? DateTime.tryParse(json['finishDate'] as String)
        : null,
    repeatCount: (json['repeatCount'] as num?)?.toInt() ?? 0,
    priority: (json['priority'] as num?)?.toInt() ?? 0,
  );

  String? titleInLanguage(TitleLanguage language) {
    return switch (language) {
      TitleLanguage.source => null,
      TitleLanguage.english => englishTitle,
      TitleLanguage.japanese => japaneseTitle,
      TitleLanguage.romaji => romajiTitle,
    };
  }

  String titleFor(TitleLanguage language) {
    final preferred = titleInLanguage(language);
    return preferred?.trim().isNotEmpty == true ? preferred! : title;
  }
}

class UnifiedMediaItem {
  final int malId;
  final String title;
  final String _posterImage;
  final MediaType mediaType;
  final Map<ServiceType, MediaItem> services;

  const UnifiedMediaItem({
    required this.malId,
    required this.title,
    this._posterImage = '',
    required this.mediaType,
    required this.services,
  });

  UnifiedMediaItem copyWith({
    int? malId,
    String? title,
    String? posterImage,
    MediaType? mediaType,
    Map<ServiceType, MediaItem>? services,
  }) {
    return UnifiedMediaItem(
      malId: malId ?? this.malId,
      title: title ?? this.title,
      posterImage: posterImage ?? _posterImage,
      mediaType: mediaType ?? this.mediaType,
      services: services ?? this.services,
    );
  }

  String get posterImage => resolvedPosterImage;

  String titleFor(TitleLanguage language) {
    if (language == TitleLanguage.source) return title;
    final values = services.values
        .map((item) => item.titleInLanguage(language))
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty);
    return values.firstOrNull ?? title;
  }

  bool matchesTitleQuery(String query) {
    final normalizedQuery = query.toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    bool matches(String? value) =>
        value?.toLowerCase().contains(normalizedQuery) ?? false;

    return matches(title) ||
        services.values.any(
          (item) => [
            item.title,
            item.englishTitle,
            item.japaneseTitle,
            item.romajiTitle,
            ...item.alternativeTitles,
          ].any(matches),
        );
  }

  String get resolvedPosterImage {
    final malItem = services[ServiceType.mal];
    if (malItem?.posterImage != null && malItem!.posterImage.isNotEmpty) {
      return malItem.posterImage;
    }
    const priorityOrder = [
      ServiceType.anilist,
      ServiceType.shikimori,
      ServiceType.kitsu,
      ServiceType.mangabaka,
      ServiceType.mangaupdates,
      ServiceType.simkl,
    ];
    for (final service in priorityOrder) {
      final item = services[service];
      if (item?.posterImage != null && item!.posterImage.isNotEmpty) {
        return item.posterImage;
      }
    }
    for (final item in services.values) {
      if (item.posterImage.isNotEmpty) {
        return item.posterImage;
      }
    }
    return _posterImage;
  }

  int? get resolvedTotalProgress {
    final malItem = services[ServiceType.mal];
    if (malItem?.totalProgress != null && malItem!.totalProgress! > 0) {
      return malItem.totalProgress;
    }
    const priorityOrder = [
      ServiceType.anilist,
      ServiceType.shikimori,
      ServiceType.kitsu,
      ServiceType.mangabaka,
      ServiceType.mangaupdates,
      ServiceType.simkl,
    ];
    for (final service in priorityOrder) {
      final item = services[service];
      if (item?.totalProgress != null && item!.totalProgress! > 0) {
        return item.totalProgress;
      }
    }
    for (final item in services.values) {
      if (item.totalProgress != null && item.totalProgress! > 0) {
        return item.totalProgress;
      }
    }
    return null;
  }

  int? get maxTotalProgress {
    int? maxTotal;
    for (final item in services.values) {
      if (item.totalProgress != null && item.totalProgress! > 0) {
        if (maxTotal == null || item.totalProgress! > maxTotal) {
          maxTotal = item.totalProgress;
        }
      }
    }
    return maxTotal;
  }

  String get malTitle {
    final malItem = services[ServiceType.mal];
    if (malItem != null && malItem.title.isNotEmpty) {
      return malItem.title;
    }
    return title;
  }

  int get malScore {
    final malItem = services[ServiceType.mal];
    if (malItem != null && malItem.score > 0) {
      return malItem.score;
    }
    for (final item in services.values) {
      if (item.score > 0) return item.score;
    }
    return 0;
  }

  int get malProgress {
    final malItem = services[ServiceType.mal];
    if (malItem != null) {
      return malItem.progress;
    }
    int maxP = 0;
    for (final item in services.values) {
      if (item.progress > maxP) maxP = item.progress;
    }
    return maxP;
  }

  DateTime? get malUpdatedAt {
    final malItem = services[ServiceType.mal];
    if (malItem?.updatedAt != null) {
      return malItem!.updatedAt;
    }
    DateTime? latest;
    for (final item in services.values) {
      if (item.updatedAt != null) {
        if (latest == null || item.updatedAt!.isAfter(latest)) {
          latest = item.updatedAt;
        }
      }
    }
    return latest;
  }

  DateTime? get malCreatedAt {
    final malItem = services[ServiceType.mal];
    if (malItem?.createdAt != null) {
      return malItem!.createdAt;
    }
    if (malItem?.startDate != null) {
      return malItem!.startDate;
    }
    if (malItem?.updatedAt != null) {
      return malItem!.updatedAt;
    }
    for (final item in services.values) {
      if (item.createdAt != null) return item.createdAt;
      if (item.startDate != null) return item.startDate;
      if (item.updatedAt != null) return item.updatedAt;
    }
    return null;
  }

  DateTime? get malStartDate {
    final malItem = services[ServiceType.mal];
    if (malItem?.startDate != null) {
      return malItem!.startDate;
    }
    for (final item in services.values) {
      if (item.startDate != null) return item.startDate;
    }
    return null;
  }

  DateTime? get malFinishDate {
    final malItem = services[ServiceType.mal];
    if (malItem?.finishDate != null) {
      return malItem!.finishDate;
    }
    for (final item in services.values) {
      if (item.finishDate != null) return item.finishDate;
    }
    return null;
  }

  int get malRepeatCount {
    final malItem = services[ServiceType.mal];
    if (malItem != null && malItem.repeatCount > 0) {
      return malItem.repeatCount;
    }
    int maxR = 0;
    for (final item in services.values) {
      if (item.repeatCount > maxR) maxR = item.repeatCount;
    }
    return maxR;
  }

  int get malPriority {
    final malItem = services[ServiceType.mal];
    if (malItem != null && malItem.priority > 0) {
      return malItem.priority;
    }
    int maxP = 0;
    for (final item in services.values) {
      if (item.priority > maxP) maxP = item.priority;
    }
    return maxP;
  }

  factory UnifiedMediaItem.mockAnime() => UnifiedMediaItem(
    malId: 1,
    title: 'Anime Title',
    posterImage: 'https://cdn.myanimelist.net/images/anime/1169/158763l.jpg',
    mediaType: MediaType.anime,
    services: {
      ServiceType.mal: MediaItem(
        id: 1,
        malId: 1,
        title: 'Anime Title',
        status: 'watching',
        score: 9,
        progress: 10,
        totalProgress: 24,
        posterImage:
            'https://cdn.myanimelist.net/images/anime/1169/158763l.jpg',
        service: ServiceType.mal,
        mediaType: MediaType.anime,
      ),
    },
  );

  factory UnifiedMediaItem.mockManga() => UnifiedMediaItem(
    malId: 1,
    title: 'Manga Title',
    posterImage: 'https://cdn.myanimelist.net/images/anime/1169/158763l.jpg',
    mediaType: MediaType.manga,
    services: {
      ServiceType.mal: MediaItem(
        id: 1,
        malId: 1,
        title: 'Manga Title',
        status: 'watching',
        score: 9,
        progress: 10,
        totalProgress: 24,
        posterImage:
            'https://cdn.myanimelist.net/images/anime/1169/158763l.jpg',
        service: ServiceType.mal,
        mediaType: MediaType.manga,
      ),
    },
  );
}

int compareUnifiedMediaItems(
  UnifiedMediaItem a,
  UnifiedMediaItem b,
  MediaSortField field,
  SortDirection direction, [
  TitleLanguage titleLanguage = TitleLanguage.source,
]) {
  int result = 0;
  final isDesc = direction == SortDirection.descending;

  switch (field) {
    case MediaSortField.title:
      result = a
          .titleFor(titleLanguage)
          .toLowerCase()
          .compareTo(b.titleFor(titleLanguage).toLowerCase());
      if (isDesc) result = -result;
      break;
    case MediaSortField.score:
      result = isDesc
          ? b.malScore.compareTo(a.malScore)
          : a.malScore.compareTo(b.malScore);
      break;
    case MediaSortField.progress:
      result = isDesc
          ? b.malProgress.compareTo(a.malProgress)
          : a.malProgress.compareTo(b.malProgress);
      break;
    case MediaSortField.updatedAt:
      result = _compareNullableDates(a.malUpdatedAt, b.malUpdatedAt, isDesc);
      break;
    case MediaSortField.createdAt:
      result = _compareNullableDates(a.malCreatedAt, b.malCreatedAt, isDesc);
      break;
    case MediaSortField.startDate:
      result = _compareNullableDates(a.malStartDate, b.malStartDate, isDesc);
      break;
    case MediaSortField.finishDate:
      result = _compareNullableDates(a.malFinishDate, b.malFinishDate, isDesc);
      break;
    case MediaSortField.repeats:
      result = isDesc
          ? b.malRepeatCount.compareTo(a.malRepeatCount)
          : a.malRepeatCount.compareTo(b.malRepeatCount);
      break;
    case MediaSortField.priority:
      result = isDesc
          ? b.malPriority.compareTo(a.malPriority)
          : a.malPriority.compareTo(b.malPriority);
      break;
  }

  if (result == 0) {
    result = a
        .titleFor(titleLanguage)
        .toLowerCase()
        .compareTo(b.titleFor(titleLanguage).toLowerCase());
  }

  return result;
}

int _compareNullableDates(DateTime? a, DateTime? b, bool isDescending) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return isDescending ? b.compareTo(a) : a.compareTo(b);
}

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'watching' || 'reading':
      return Colors.blue.shade700;
    case 'completed':
      return Colors.green.shade700;
    case 'on_hold':
      return Colors.orange.shade700;
    case 'dropped':
      return Colors.red.shade700;
    case 'plan_to_watch' || 'plan_to_read':
    default:
      return Colors.grey.shade700;
  }
}

String getStatusLabel(String status, MediaType type, BuildContext context) {
  switch (type) {
    case MediaType.anime:
      switch (status.toLowerCase()) {
        case 'watching':
          return AppLocalizations.of(context).watching;
        case 'completed':
          return AppLocalizations.of(context).done;
        case 'on_hold':
          return AppLocalizations.of(context).onHold;
        case 'dropped':
          return AppLocalizations.of(context).dropped;
        case 'plan_to_watch':
        default:
          return AppLocalizations.of(context).planToWatch;
      }
    case MediaType.manga:
      switch (status.toLowerCase()) {
        case 'watching':
          return AppLocalizations.of(context).reading;
        case 'completed':
          return AppLocalizations.of(context).done;
        case 'on_hold':
          return AppLocalizations.of(context).onHold;
        case 'dropped':
          return AppLocalizations.of(context).dropped;
        case 'plan_to_watch':
        default:
          return AppLocalizations.of(context).planToRead;
      }
  }
}

class SyncAction {
  final ServiceType targetService;
  final int targetId;
  final int? targetMalId;
  final String title;
  final String posterImage;
  final MediaType mediaType;
  final String newStatus;
  final int newScore;
  final int newProgress;
  final String? oldStatus;
  final int? oldScore;
  final int? oldProgress;
  final bool isAdd;
  bool isSelected;

  SyncAction({
    required this.targetService,
    required this.targetId,
    this.targetMalId,
    required this.title,
    required this.posterImage,
    this.mediaType = MediaType.anime,
    required this.newStatus,
    required this.newScore,
    required this.newProgress,
    this.oldStatus,
    this.oldScore,
    this.oldProgress,
    required this.isAdd,
    this.isSelected = true,
  });
}

class ServiceCredentials {
  final String? accessToken;
  final String? refreshToken;
  final String? username;
  final String? userId;
  final String? clientId;
  final String? clientSecret;
  final DateTime? expiresAt;
  final bool isConnected;

  const ServiceCredentials({
    this.accessToken,
    this.refreshToken,
    this.username,
    this.userId,
    this.clientId,
    this.clientSecret,
    this.expiresAt,
    this.isConnected = false,
  });

  ServiceCredentials copyWith({
    String? accessToken,
    String? refreshToken,
    String? username,
    String? userId,
    String? clientId,
    String? clientSecret,
    DateTime? expiresAt,
    bool? isConnected,
  }) {
    return ServiceCredentials(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      username: username ?? this.username,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      expiresAt: expiresAt ?? this.expiresAt,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'username': username,
    'userId': userId,
    'clientId': clientId,
    'clientSecret': clientSecret,
    'expiresAt': expiresAt?.toIso8601String(),
    'isConnected': isConnected,
  };

  factory ServiceCredentials.fromJson(Map<String, dynamic> json) =>
      ServiceCredentials(
        accessToken: json['accessToken'] as String?,
        refreshToken: json['refreshToken'] as String?,
        username: json['username'] as String?,
        userId: json['userId'] as String?,
        clientId: json['clientId'] as String?,
        clientSecret: json['clientSecret'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String)
            : null,
        isConnected: json['isConnected'] as bool? ?? false,
      );
}
