import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import 'anilist_rate_limiter.dart';
import 'storage_service.dart';

class AnilistService {
  final StorageService _storage;
  static const _graphqlUrl = 'https://graphql.anilist.co';

  final Map<MediaType, List<MediaItem>> _listCache = {};
  final Map<MediaType, DateTime> _listCacheTime = {};
  static const Duration _cacheTtl = Duration(minutes: 5);
  final Map<String, int?> _malIdLookupCache = {};

  AnilistService(this._storage);

  void clearCache() {
    _listCache.clear();
    _listCacheTime.clear();
    _malIdLookupCache.clear();
  }

  @visibleForTesting
  Map<MediaType, List<MediaItem>> get listCache => _listCache;

  @visibleForTesting
  Map<String, int?> get malIdLookupCache => _malIdLookupCache;

  ServiceCredentials get credentials =>
      _storage.getCredentials(ServiceType.anilist);

  bool get isAuthenticated =>
      credentials.accessToken != null && credentials.accessToken!.isNotEmpty;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'AniSync/1.0.0',
    };
    if (isAuthenticated) {
      headers['Authorization'] = 'Bearer ${credentials.accessToken}';
    }
    return headers;
  }

  static String normalizeStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'CURRENT':
      case 'REPEATING':
        return 'watching';
      case 'COMPLETED':
        return 'completed';
      case 'PAUSED':
        return 'on_hold';
      case 'DROPPED':
        return 'dropped';
      case 'PLANNING':
        return 'plan_to_watch';
      default:
        return 'plan_to_watch';
    }
  }

  static String toAnilistStatus(String normalized) {
    switch (normalized.toLowerCase()) {
      case 'watching':
      case 'reading':
        return 'CURRENT';
      case 'completed':
        return 'COMPLETED';
      case 'on_hold':
        return 'PAUSED';
      case 'dropped':
        return 'DROPPED';
      case 'plan_to_watch':
      case 'plan_to_read':
      default:
        return 'PLANNING';
    }
  }

  Future<String?> fetchViewerUsername() async {
    if (!isAuthenticated) return null;

    const query = 'query { Viewer { id name } }';
    try {
      final resp = await AnilistRateLimiter.post(
        url: Uri.parse(_graphqlUrl),
        headers: _headers(),
        body: {'query': query},
      );

      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final viewer = data['data']?['Viewer'] as Map<String, dynamic>?;
      if (viewer != null) {
        final name = viewer['name'] as String?;
        final id = viewer['id']?.toString();
        if (name != null) {
          await _storage.saveCredentials(
            ServiceType.anilist,
            credentials.copyWith(username: name, userId: id),
          );
          return name;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<MediaItem>> fetchList(
    MediaType type, {
    String? status,
    int limit = 0,
    bool forceRefresh = false,
  }) async {
    if (!isAuthenticated) return [];

    if (!forceRefresh &&
        status == null &&
        limit == 0 &&
        _listCache.containsKey(type)) {
      final cachedTime = _listCacheTime[type];
      if (cachedTime != null &&
          DateTime.now().difference(cachedTime) < _cacheTtl) {
        return List<MediaItem>.from(_listCache[type]!);
      }
    }

    final userId = credentials.userId;
    final username =
        credentials.username ??
        ((userId == null || userId.isEmpty)
            ? await fetchViewerUsername()
            : null);
    if ((username == null || username.isEmpty) &&
        (userId == null || userId.isEmpty)) {
      return [];
    }

    const query = r'''
      query ($userId: Int, $userName: String, $type: MediaType, $chunk: Int) {
        MediaListCollection(userId: $userId, userName: $userName, type: $type, chunk: $chunk) {
          hasNextChunk
          lists {
            name
            status
            isCustomList
            entries {
              id
              mediaId
              status
              score(format: POINT_10)
              progress
              repeat
              priority
              updatedAt
              createdAt
              startedAt {
                year
                month
                day
              }
              completedAt {
                year
                month
                day
              }
              media {
                id
                idMal
                title {
                  romaji
                  english
                  native
                  userPreferred
                }
                synonyms
                episodes
                chapters
                coverImage {
                  extraLarge
                  large
                  medium
                }
              }
            }
          }
        }
      }
    ''';

    final results = <MediaItem>[];
    final seenMediaIds = <int>{};
    int chunk = 1;
    bool hasNextChunk = true;

    while (hasNextChunk) {
      if (chunk > 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final variables = <String, dynamic>{
        'type': type == MediaType.anime ? 'ANIME' : 'MANGA',
        'chunk': chunk,
      };
      final userIdInt = int.tryParse(userId ?? '');
      if (userIdInt != null && userIdInt > 0) {
        variables['userId'] = userIdInt;
      }
      if (username != null && username.isNotEmpty) {
        variables['userName'] = username;
      }

      final resp = await AnilistRateLimiter.post(
        url: Uri.parse(_graphqlUrl),
        headers: _headers(),
        body: {'query': query, 'variables': variables},
      );

      if (resp.statusCode != 200) {
        throw Exception(
          'Failed to fetch AniList (status ${resp.statusCode}): ${resp.body}',
        );
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final collection =
          data['data']?['MediaListCollection'] as Map<String, dynamic>?;
      if (collection == null) break;

      hasNextChunk = (collection['hasNextChunk'] as bool?) ?? false;
      final lists = (collection['lists'] as List<dynamic>?) ?? [];

      for (final l in lists) {
        final isCustom = (l['isCustomList'] as bool?) ?? false;
        if (isCustom) continue;

        final entries = (l['entries'] as List<dynamic>?) ?? [];
        for (final e in entries) {
          final media = (e['media'] as Map<String, dynamic>?) ?? {};
          final mediaId =
              (e['mediaId'] as num?)?.toInt() ??
              (media['id'] as num?)?.toInt() ??
              0;
          if (mediaId == 0 || seenMediaIds.contains(mediaId)) continue;
          seenMediaIds.add(mediaId);

          final rawStatus = (e['status'] as String?) ?? 'PLANNING';
          final normStatus = normalizeStatus(rawStatus);

          if (status != null &&
              status.isNotEmpty &&
              normStatus != status.toLowerCase()) {
            continue;
          }

          final titleMap = (media['title'] as Map<String, dynamic>?) ?? {};
          final title =
              (titleMap['userPreferred'] as String?) ??
              (titleMap['romaji'] as String?) ??
              (titleMap['english'] as String?) ??
              'Unknown';
          final englishTitle = titleMap['english'] as String?;
          final japaneseTitle = titleMap['native'] as String?;
          final romajiTitle = titleMap['romaji'] as String?;
          final alternativeTitles =
              (media['synonyms'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList() ??
              const [];

          final coverMap = (media['coverImage'] as Map<String, dynamic>?) ?? {};
          final poster =
              (coverMap['extraLarge'] as String?) ??
              (coverMap['large'] as String?) ??
              (coverMap['medium'] as String?) ??
              '';

          final score = (e['score'] as num?)?.toInt() ?? 0;
          final progress = (e['progress'] as num?)?.toInt() ?? 0;
          final totalProgress = type == MediaType.anime
              ? (media['episodes'] as num?)?.toInt()
              : (media['chapters'] as num?)?.toInt();
          final idMal = (media['idMal'] as num?)?.toInt();

          if (idMal != null && idMal > 0 && mediaId > 0) {
            _malIdLookupCache['$type:$idMal'] = mediaId;
          }

          final updatedAtTs = (e['updatedAt'] as num?)?.toInt();
          final updatedAt = updatedAtTs != null
              ? DateTime.fromMillisecondsSinceEpoch(updatedAtTs * 1000)
              : null;
          final createdAtTs = (e['createdAt'] as num?)?.toInt();
          final createdAt = createdAtTs != null
              ? DateTime.fromMillisecondsSinceEpoch(createdAtTs * 1000)
              : null;

          DateTime? parseFuzzy(Map<String, dynamic>? date) {
            if (date == null) return null;
            final y = (date['year'] as num?)?.toInt();
            if (y == null) return null;
            final m = (date['month'] as num?)?.toInt() ?? 1;
            final d = (date['day'] as num?)?.toInt() ?? 1;
            return DateTime(y, m, d);
          }

          final startDate = parseFuzzy(e['startedAt'] as Map<String, dynamic>?);
          final finishDate = parseFuzzy(
            e['completedAt'] as Map<String, dynamic>?,
          );
          final repeatCount = (e['repeat'] as num?)?.toInt() ?? 0;
          final priority = (e['priority'] as num?)?.toInt() ?? 0;

          results.add(
            MediaItem(
              id: mediaId,
              listEntryId: (e['id'] as num?)?.toInt(),
              malId: idMal != null && idMal > 0 ? idMal : null,
              title: title,
              englishTitle: englishTitle,
              japaneseTitle: japaneseTitle,
              romajiTitle: romajiTitle,
              alternativeTitles: alternativeTitles,
              status: normStatus,
              originalStatus: rawStatus,
              score: score > 10 ? (score / 10).round() : score,
              progress: progress,
              totalProgress: totalProgress,
              posterImage: poster,
              service: ServiceType.anilist,
              mediaType: type,
              updatedAt: updatedAt,
              createdAt: createdAt,
              startDate: startDate,
              finishDate: finishDate,
              repeatCount: repeatCount,
              priority: priority,
            ),
          );

          if (limit > 0 && results.length >= limit) {
            return results;
          }
        }
      }

      chunk++;
      if (chunk > 20) break;
    }

    if (status == null && limit == 0) {
      _listCache[type] = List<MediaItem>.from(results);
      _listCacheTime[type] = DateTime.now();
    }

    return results;
  }

  Future<void> updateItem({
    required int id,
    required MediaType type,
    required String status,
    required int score,
    required int progress,
  }) async {
    if (!isAuthenticated) throw Exception('AniList is not authenticated');

    const mutation = r'''
      mutation ($mediaId: Int, $status: MediaListStatus, $scoreRaw: Int, $progress: Int) {
        SaveMediaListEntry(mediaId: $mediaId, status: $status, scoreRaw: $scoreRaw, progress: $progress) {
          id
          status
          progress
          score
        }
      }
    ''';

    final variables = <String, dynamic>{
      'mediaId': id,
      'status': toAnilistStatus(status),
      'progress': progress,
      'scoreRaw': score * 10,
    };

    final resp = await AnilistRateLimiter.post(
      url: Uri.parse(_graphqlUrl),
      headers: _headers(),
      body: {'query': mutation, 'variables': variables},
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to update AniList entry: ${resp.body}');
    }

    _listCache.remove(type);
    _listCacheTime.remove(type);
  }

  Future<void> removeItem({
    required int listEntryId,
    required MediaType type,
  }) async {
    if (!isAuthenticated) throw Exception('AniList is not authenticated');

    const mutation = r'''
      mutation ($id: Int!) {
        DeleteMediaListEntry(id: $id) {
          deleted
        }
      }
    ''';

    final resp = await AnilistRateLimiter.post(
      url: Uri.parse(_graphqlUrl),
      headers: _headers(),
      body: {
        'query': mutation,
        'variables': {'id': listEntryId},
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to remove AniList entry: ${resp.body}');
    }

    final response = jsonDecode(resp.body) as Map<String, dynamic>;
    final errors = response['errors'] as List<dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception('Failed to remove AniList entry: ${errors.first}');
    }
    final deleted =
        (response['data']?['DeleteMediaListEntry']
                as Map<String, dynamic>?)?['deleted']
            as bool?;
    if (deleted != true) {
      throw Exception('AniList did not remove the list entry.');
    }

    _listCache.remove(type);
    _listCacheTime.remove(type);
  }

  Future<List<MediaItem>> search(String query, MediaType type) async {
    const searchQuery = r'''
      query ($search: String, $type: MediaType) {
        Page(perPage: 20) {
          media(search: $search, type: $type) {
            id
            idMal
            title {
              romaji
              english
              native
              userPreferred
            }
            episodes
            chapters
            coverImage {
              large
            }
          }
        }
      }
    ''';

    final variables = {
      'search': query,
      'type': type == MediaType.anime ? 'ANIME' : 'MANGA',
    };

    final resp = await AnilistRateLimiter.post(
      url: Uri.parse(_graphqlUrl),
      headers: _headers(),
      body: {'query': searchQuery, 'variables': variables},
    );

    if (resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final mediaList = (data['data']?['Page']?['media'] as List<dynamic>?) ?? [];

    return mediaList.map((m) {
      final titleMap = (m['title'] as Map<String, dynamic>?) ?? {};
      final title =
          (titleMap['userPreferred'] as String?) ??
          (titleMap['romaji'] as String?) ??
          (titleMap['english'] as String?) ??
          'Unknown';
      final coverMap = (m['coverImage'] as Map<String, dynamic>?) ?? {};
      final idMal = (m['idMal'] as num?)?.toInt();
      return MediaItem(
        id: (m['id'] as num).toInt(),
        malId: idMal != null && idMal > 0 ? idMal : null,
        title: title,
        englishTitle: titleMap['english'] as String?,
        japaneseTitle: titleMap['native'] as String?,
        romajiTitle: titleMap['romaji'] as String?,
        status: 'plan_to_watch',
        score: 0,
        progress: 0,
        totalProgress: type == MediaType.anime
            ? (m['episodes'] as num?)?.toInt()
            : (m['chapters'] as num?)?.toInt(),
        posterImage: (coverMap['large'] as String?) ?? '',
        service: ServiceType.anilist,
        mediaType: type,
      );
    }).toList();
  }

  Future<int?> findMediaIdByMalId(int malId, MediaType type) async {
    if (malId <= 0) return null;
    final cacheKey = '$type:$malId';
    if (_malIdLookupCache.containsKey(cacheKey)) {
      return _malIdLookupCache[cacheKey];
    }

    const query = r'''
      query ($idMal: Int, $type: MediaType) {
        Media(idMal: $idMal, type: $type) {
          id
        }
      }
    ''';
    try {
      final resp = await AnilistRateLimiter.post(
        url: Uri.parse(_graphqlUrl),
        headers: _headers(),
        body: {
          'query': query,
          'variables': {
            'idMal': malId,
            'type': type == MediaType.anime ? 'ANIME' : 'MANGA',
          },
        },
        timeout: const Duration(seconds: 5),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final id = (data['data']?['Media']?['id'] as num?)?.toInt();
        if (id != null && id > 0) {
          _malIdLookupCache[cacheKey] = id;
          return id;
        } else {
          _malIdLookupCache[cacheKey] = null;
        }
      } else if (resp.statusCode == 404) {
        _malIdLookupCache[cacheKey] = null;
      }
    } catch (_) {}
    return null;
  }
}
