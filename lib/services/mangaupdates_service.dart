import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'storage_service.dart';

class MangaUpdatesService {
  final StorageService _storage;
  final http.Client _client;

  static const String baseUrl = 'https://api.mangaupdates.com/v1';

  MangaUpdatesService(this._storage, {http.Client? client})
      : _client = client ?? http.Client();

  bool get isAuthenticated {
    final creds = _storage.getCredentials(ServiceType.mangaupdates);
    return creds.isConnected || (creds.accessToken?.isNotEmpty ?? false);
  }

  Map<String, String> _buildHeaders() {
    final creds = _storage.getCredentials(ServiceType.mangaupdates);
    final token = creds.accessToken?.trim() ?? '';
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String sanitizePosterUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('//')) {
      trimmed = 'https:$trimmed';
    } else if (trimmed.startsWith('http://')) {
      trimmed = 'https://${trimmed.substring(7)}';
    } else if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  static String extractPoster(dynamic imageObj) {
    if (imageObj == null) return '';
    if (imageObj is String) {
      return sanitizePosterUrl(imageObj);
    }
    if (imageObj is Map) {
      final urlObj = imageObj['url'];
      if (urlObj is String) {
        return sanitizePosterUrl(urlObj);
      }
      if (urlObj is Map) {
        final orig = urlObj['original']?.toString() ?? '';
        if (orig.isNotEmpty) return sanitizePosterUrl(orig);
        final thumb = urlObj['thumb']?.toString() ?? '';
        if (thumb.isNotEmpty) return sanitizePosterUrl(thumb);
      }
      final directOrig = imageObj['original']?.toString() ?? '';
      if (directOrig.isNotEmpty) return sanitizePosterUrl(directOrig);
      final directThumb = imageObj['thumb']?.toString() ?? '';
      if (directThumb.isNotEmpty) return sanitizePosterUrl(directThumb);
    }
    return '';
  }

  Future<String> fetchSeriesPoster(int seriesId) async {
    if (seriesId <= 0) return '';
    try {
      final cached = _storage.getMangaUpdatesPostersCache()[seriesId];
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      final resp = await _client.get(
        Uri.parse('$baseUrl/series/$seriesId'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'AniSync/1.0.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final poster = extractPoster(data['image']);
        if (poster.isNotEmpty) {
          await _storage.saveSingleMangaUpdatesPoster(seriesId, poster);
          return poster;
        }
      }
    } catch (e) {
      debugPrint('Error fetching MangaUpdates poster for $seriesId: $e');
    }
    return '';
  }

  Map<String, int>? _cachedListIdByType;

  void clearCache() {
    _cachedListIdByType = null;
  }

  Future<Map<String, int>> _getListsMap() async {
    if (_cachedListIdByType != null) {
      return _cachedListIdByType!;
    }

    final resp = await _client.get(
      Uri.parse('$baseUrl/lists'),
      headers: _buildHeaders(),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch MangaUpdates lists (${resp.statusCode}): ${resp.body}',
      );
    }

    final list = jsonDecode(resp.body) as List<dynamic>;
    final map = <String, int>{};
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final listId = (item['list_id'] as num?)?.toInt();
        final type = item['type'] as String?;
        if (listId != null && type != null) {
          map[type.toLowerCase()] = listId;
        }
      }
    }

    _cachedListIdByType = map;
    return map;
  }

  String normalizeListType(String type) {
    switch (type.toLowerCase()) {
      case 'read':
        return 'watching';
      case 'complete':
        return 'completed';
      case 'hold':
        return 'on_hold';
      case 'unfinished':
        return 'dropped';
      case 'wish':
      default:
        return 'plan_to_watch';
    }
  }

  String denormalizeStatusToListType(String status) {
    switch (status.toLowerCase()) {
      case 'watching':
      case 'reading':
        return 'read';
      case 'completed':
        return 'complete';
      case 'on_hold':
      case 'paused':
        return 'hold';
      case 'dropped':
        return 'unfinished';
      case 'plan_to_watch':
      case 'plan_to_read':
      default:
        return 'wish';
    }
  }

  Future<ServiceCredentials> login({
    required String username,
    required String password,
  }) async {
    final resp = await _client.put(
      Uri.parse('$baseUrl/account/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (resp.statusCode != 200) {
      String message = 'Login failed (${resp.statusCode})';
      try {
        final err = jsonDecode(resp.body) as Map<String, dynamic>;
        if (err['reason'] != null) {
          message = err['reason'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final context = data['context'] as Map<String, dynamic>?;
    final sessionToken = context?['session_token'] as String?;

    if (sessionToken == null || sessionToken.isEmpty) {
      throw Exception('MangaUpdates did not return a session token');
    }

    final creds = ServiceCredentials(
      accessToken: sessionToken,
      username: username,
      isConnected: true,
    );

    await _storage.saveCredentials(ServiceType.mangaupdates, creds);
    _cachedListIdByType = null;
    return creds;
  }

  Future<List<MediaItem>> fetchList(
    MediaType type, {
    String? status,
    int? limit,
  }) async {
    if (type == MediaType.anime) {
      return [];
    }

    if (!isAuthenticated) {
      throw Exception('MangaUpdates is not authenticated');
    }

    final listsMap = await _getListsMap();
    final items = <MediaItem>[];
    final posterCache = _storage.getMangaUpdatesPostersCache();
    final newlyFoundPosters = <int, String>{};

    for (final entry in listsMap.entries) {
      final listType = entry.key;
      final listId = entry.value;
      final normalizedStatus = normalizeListType(listType);

      if (status != null && status != 'all' && normalizedStatus != status) {
        continue;
      }

      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final resp = await _client.post(
          Uri.parse('$baseUrl/lists/$listId/search'),
          headers: _buildHeaders(),
          body: jsonEncode({
            'page': page,
            'perpage': 100,
          }),
        );

        if (resp.statusCode != 200) {
          debugPrint(
            'Failed to search MangaUpdates list $listId (${resp.statusCode}): ${resp.body}',
          );
          break;
        }

        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        final totalHits = (data['total_hits'] as num?)?.toInt() ?? 0;

        for (final res in results) {
          if (res is! Map) continue;
          final record = res['record'] is Map ? res['record'] as Map : {};
          final metadata = res['metadata'] is Map ? res['metadata'] as Map : {};
          final seriesRecord =
              record['series'] is Map ? record['series'] as Map : {};
          final seriesMeta =
              metadata['series'] is Map ? metadata['series'] as Map : {};

          final seriesId = (seriesRecord['id'] as num?)?.toInt() ??
              int.tryParse(seriesRecord['id']?.toString() ?? '') ??
              (seriesMeta['series_id'] as num?)?.toInt() ??
              int.tryParse(seriesMeta['series_id']?.toString() ?? '') ??
              0;
          if (seriesId <= 0) continue;

          final title = seriesRecord['title']?.toString() ??
              seriesMeta['title']?.toString() ??
              'Manga #$seriesId';

          final statusObj =
              record['status'] is Map ? record['status'] as Map : null;
          final rawChapter = (statusObj?['chapter'] as num?)?.toInt() ??
              int.tryParse(statusObj?['chapter']?.toString() ?? '') ??
              0;

          final isComplete = normalizedStatus == 'completed';
          final progress = (!isComplete && rawChapter <= 1) ? 0 : rawChapter;
          final effectiveStatus = (!isComplete && rawChapter <= 1 && normalizedStatus == 'watching')
              ? 'plan_to_watch'
              : normalizedStatus;

          final userRating = (metadata['user_rating'] as num?)?.round() ??
              int.tryParse(metadata['user_rating']?.toString() ?? '') ??
              0;

          String poster = extractPoster(seriesMeta['image']);
          if (poster.isEmpty) {
            poster = extractPoster(metadata['image']);
          }
          if (poster.isEmpty) {
            poster = extractPoster(seriesRecord['image']);
          }
          if (poster.isEmpty) {
            poster = extractPoster(record['image']);
          }
          if (poster.isEmpty) {
            poster = extractPoster(res['image']);
          }
          if (poster.isEmpty) {
            poster = posterCache[seriesId] ?? '';
          }
          if (poster.isNotEmpty && posterCache[seriesId] == null) {
            newlyFoundPosters[seriesId] = poster;
          }

          items.add(
            MediaItem(
              id: seriesId,
              title: title,
              status: effectiveStatus,
              score: userRating,
              progress: progress,
              posterImage: poster,
              service: ServiceType.mangaupdates,
              mediaType: MediaType.manga,
              originalStatus: listType,
            ),
          );

          if (limit != null && items.length >= limit) {
            break;
          }
        }

        if (limit != null && items.length >= limit) {
          hasMore = false;
          break;
        }

        if (results.isEmpty || page * 100 >= totalHits) {
          hasMore = false;
        } else {
          page++;
        }
      }

      if (limit != null && items.length >= limit) {
        break;
      }
    }

    if (newlyFoundPosters.isNotEmpty) {
      posterCache.addAll(newlyFoundPosters);
      await _storage.saveMangaUpdatesPostersCache(posterCache);
    }

    final missingPosters = items.where((it) => it.posterImage.isEmpty).toList();
    if (missingPosters.isNotEmpty) {
      const batchSize = 6;
      for (var i = 0; i < missingPosters.length; i += batchSize) {
        final batch = missingPosters.skip(i).take(batchSize);
        await Future.wait(batch.map((it) async {
          final p = await fetchSeriesPoster(it.id);
          if (p.isNotEmpty) {
            final idx = items.indexWhere((x) => x.id == it.id);
            if (idx != -1) {
              items[idx] = items[idx].copyWith(posterImage: p);
            }
          }
        }));
      }
    }

    return limit != null && items.length > limit ? items.sublist(0, limit) : items;
  }

  Future<void> updateItem({
    required int id,
    required MediaType type,
    required String status,
    required int score,
    required int progress,
  }) async {
    if (type == MediaType.anime) return;
    if (!isAuthenticated) {
      throw Exception('MangaUpdates is not authenticated');
    }

    final listsMap = await _getListsMap();
    final targetType = denormalizeStatusToListType(status);
    final targetListId = listsMap[targetType] ?? listsMap['read'] ?? 0;

    final effectiveChapter = progress <= 0 ? 0 : progress;

    final updatePayload = [
      {
        'series': {'id': id},
        'list_id': targetListId,
        'status': {
          'chapter': effectiveChapter,
        },
      }
    ];

    final headers = _buildHeaders();

    final updateResp = await _client.post(
      Uri.parse('$baseUrl/lists/series/update'),
      headers: headers,
      body: jsonEncode(updatePayload),
    );

    if (updateResp.statusCode != 200) {
      final addResp = await _client.post(
        Uri.parse('$baseUrl/lists/series'),
        headers: headers,
        body: jsonEncode(updatePayload),
      );
      if (addResp.statusCode != 200) {
        throw Exception(
          'Failed to add/update MangaUpdates series $id (${addResp.statusCode}): ${addResp.body}',
        );
      }
    }

    if (score > 0) {
      try {
        await _client.put(
          Uri.parse('$baseUrl/series/$id/rating'),
          headers: headers,
          body: jsonEncode({
            'rating': score,
          }),
        );
      } catch (e) {
        debugPrint('Failed to update MangaUpdates rating for $id: $e');
      }
    }
  }
}
