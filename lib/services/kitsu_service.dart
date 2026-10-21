import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'storage_service.dart';

class KitsuService {
  final StorageService _storage;
  final http.Client? client;
  static const _baseUrl = 'https://kitsu.app/api/edge';

  KitsuService(this._storage, {this.client});

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) {
    final c = client;
    return c != null
        ? c.get(url, headers: headers)
        : http.get(url, headers: headers);
  }

  Future<http.Response> _patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final c = client;
    return c != null
        ? c.patch(url, headers: headers, body: body)
        : http.patch(url, headers: headers, body: body);
  }

  Future<http.Response> _post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final c = client;
    return c != null
        ? c.post(url, headers: headers, body: body)
        : http.post(url, headers: headers, body: body);
  }

  ServiceCredentials get credentials =>
      _storage.getCredentials(ServiceType.kitsu);

  bool get isAuthenticated =>
      credentials.accessToken != null && credentials.accessToken!.isNotEmpty;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/vnd.api+json',
      'Content-Type': 'application/vnd.api+json',
      'User-Agent': 'MoeSync/1.0.0',
    };
    if (isAuthenticated) {
      headers['Authorization'] = 'Bearer ${credentials.accessToken}';
    }
    return headers;
  }

  static String normalizeStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'current':
        return 'watching';
      case 'completed':
        return 'completed';
      case 'on_hold':
        return 'on_hold';
      case 'dropped':
        return 'dropped';
      case 'planned':
        return 'plan_to_watch';
      default:
        return 'plan_to_watch';
    }
  }

  static String toKitsuStatus(String normalized) {
    switch (normalized.toLowerCase()) {
      case 'watching':
      case 'reading':
        return 'current';
      case 'completed':
        return 'completed';
      case 'on_hold':
        return 'on_hold';
      case 'dropped':
        return 'dropped';
      case 'plan_to_watch':
      case 'plan_to_read':
      default:
        return 'planned';
    }
  }

  String? _cachedUserId;

  Future<String?> fetchUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    if (credentials.userId != null && credentials.userId!.isNotEmpty) {
      _cachedUserId = credentials.userId;
      return _cachedUserId;
    }

    if (!isAuthenticated) return null;

    try {
      final url = Uri.parse('$_baseUrl/users?filter[self]=true');
      final resp = await http.get(url, headers: _headers());
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final users = (data['data'] as List<dynamic>?) ?? [];
        if (users.isNotEmpty) {
          final id = users.first['id'] as String?;
          if (id != null && id.isNotEmpty) {
            _cachedUserId = id;
            await _storage.saveCredentials(
              ServiceType.kitsu,
              credentials.copyWith(userId: id),
            );
            return id;
          }
        }
      }
    } catch (_) {}

    final uname = credentials.username;
    if (uname != null && uname.isNotEmpty) {
      if (int.tryParse(uname) != null) {
        _cachedUserId = uname;
        return uname;
      }
      try {
        final url = Uri.parse(
          '$_baseUrl/users?filter[name]=${Uri.encodeComponent(uname)}',
        );
        final resp = await http.get(url, headers: _headers());
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final users = (data['data'] as List<dynamic>?) ?? [];
          if (users.isNotEmpty) {
            final id = users.first['id'] as String?;
            if (id != null && id.isNotEmpty) {
              _cachedUserId = id;
              await _storage.saveCredentials(
                ServiceType.kitsu,
                credentials.copyWith(userId: id),
              );
              return id;
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  Future<List<MediaItem>> fetchList(
    MediaType type, {
    String? status,
    int limit = 0,
  }) async {
    if (!isAuthenticated) return [];

    final userId = await fetchUserId();
    if (userId == null) return [];

    final kind = type == MediaType.anime ? 'anime' : 'manga';
    final allEntries = <dynamic>[];
    final mediaMap = <String, Map<String, dynamic>>{};

    String? nextUrl =
        '$_baseUrl/library-entries?filter[userId]=$userId&filter[kind]=$kind&include=$kind&page[limit]=500';
    if (status != null && status.isNotEmpty) {
      nextUrl += '&filter[status]=${toKitsuStatus(status)}';
    }

    while (nextUrl != null && nextUrl.isNotEmpty) {
      final resp = await http.get(Uri.parse(nextUrl), headers: _headers());
      if (resp.statusCode != 200) {
        throw Exception('Failed to fetch Kitsu entries: ${resp.body}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final entries = (data['data'] as List<dynamic>?) ?? [];
      final included = (data['included'] as List<dynamic>?) ?? [];

      for (final inc in included) {
        if (inc['type'] == kind) {
          mediaMap[inc['id'] as String] =
              inc['attributes'] as Map<String, dynamic>;
        }
      }

      allEntries.addAll(entries);

      if (limit > 0 && allEntries.length >= limit) {
        break;
      }

      final links = (data['links'] as Map<String, dynamic>?) ?? {};
      nextUrl = links['next'] as String?;
    }

    final results = <MediaItem>[];
    for (final entry in allEntries) {
      final attrs = (entry['attributes'] as Map<String, dynamic>?) ?? {};
      final rels = (entry['relationships'] as Map<String, dynamic>?) ?? {};
      final mediaData =
          (rels[kind]?['data'] as Map<String, dynamic>?) ??
          (rels['media']?['data'] as Map<String, dynamic>?) ??
          {};
      final mediaIdStr = mediaData['id']?.toString();
      final mediaId = int.tryParse(mediaIdStr ?? '') ?? 0;
      if (mediaId == 0) continue;

      final mediaAttrs = mediaMap[mediaIdStr] ?? {};
      final titlesMap = (mediaAttrs['titles'] as Map<String, dynamic>?) ?? {};
      final title =
          (mediaAttrs['canonicalTitle'] as String?) ??
          (titlesMap['en'] as String?) ??
          (titlesMap['en_jp'] as String?) ??
          (titlesMap['ja_jp'] as String?) ??
          'Unknown';
      final englishTitle = titlesMap['en'] as String?;
      final japaneseTitle = titlesMap['ja_jp'] as String?;
      final romajiTitle = titlesMap['en_jp'] as String?;

      final posterMap =
          (mediaAttrs['posterImage'] as Map<String, dynamic>?) ?? {};
      final poster =
          (posterMap['large'] as String?) ??
          (posterMap['medium'] as String?) ??
          (posterMap['original'] as String?) ??
          (posterMap['small'] as String?) ??
          '';

      final rawStatus = (attrs['status'] as String?) ?? 'planned';
      final score = _parseKitsuScore(attrs['ratingTwenty'], attrs['rating']);
      final progress = _parseInt(attrs['progress'], 0);
      final totalProgress = type == MediaType.anime
          ? _parseNullableInt(mediaAttrs['episodeCount'])
          : _parseNullableInt(mediaAttrs['chapterCount']);

      results.add(
        MediaItem(
          id: mediaId,
          title: title,
          englishTitle: englishTitle,
          japaneseTitle: japaneseTitle,
          romajiTitle: romajiTitle,
          alternativeTitles: titlesMap.values.whereType<String>().toList(),
          status: normalizeStatus(rawStatus),
          originalStatus: rawStatus,
          score: score,
          progress: progress,
          totalProgress: totalProgress,
          posterImage: poster,
          service: ServiceType.kitsu,
          mediaType: type,
        ),
      );
    }

    return results;
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  static int? _parseNullableInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  static int _parseKitsuScore(dynamic ratingTwenty, dynamic rating) {
    if (ratingTwenty != null) {
      double? val;
      if (ratingTwenty is num) {
        val = ratingTwenty.toDouble();
      } else if (ratingTwenty is String) {
        val = double.tryParse(ratingTwenty);
      }
      if (val != null) {
        return (val / 2).round().clamp(0, 10);
      }
    }
    if (rating != null) {
      double? val;
      if (rating is num) {
        val = rating.toDouble();
      } else if (rating is String) {
        val = double.tryParse(rating);
      }
      if (val != null && val > 0) {
        return val > 5.0
            ? val.round().clamp(0, 10)
            : (val * 2).round().clamp(0, 10);
      }
    }
    return 0;
  }

  Future<void> updateItem({
    required int id,
    required MediaType type,
    required String status,
    required int score,
    required int progress,
  }) async {
    if (!isAuthenticated) throw Exception('Kitsu is not authenticated');

    final userId = await fetchUserId();
    if (userId == null) throw Exception('Could not fetch Kitsu user id');

    final kind = type == MediaType.anime ? 'anime' : 'manga';
    final idParam = type == MediaType.anime ? 'animeId' : 'mangaId';
    final mediaIdStr = id.toString();
    final checkUrl = Uri.parse(
      '$_baseUrl/library-entries?filter[userId]=$userId&filter[$idParam]=$mediaIdStr',
    );

    final checkResp = await _get(checkUrl, headers: _headers());
    if (checkResp.statusCode != 200) {
      throw Exception('Failed to check Kitsu library entry');
    }

    final data = jsonDecode(checkResp.body) as Map<String, dynamic>;
    final existing = (data['data'] as List<dynamic>?) ?? [];

    final kitsuScore = score > 0 ? (score * 2).clamp(2, 20) : null;

    if (existing.isNotEmpty) {
      final entryId = existing.first['id'] as String;
      final patchUrl = Uri.parse('$_baseUrl/library-entries/$entryId');

      final body = {
        'data': {
          'id': entryId,
          'type': 'libraryEntries',
          'attributes': {
            'status': toKitsuStatus(status),
            'progress': progress,
            'ratingTwenty': kitsuScore,
          },
        },
      };

      final resp = await _patch(
        patchUrl,
        headers: _headers(),
        body: jsonEncode(body),
      );
      if (resp.statusCode != 200 && resp.statusCode != 204) {
        throw Exception('Failed to update Kitsu entry: ${resp.body}');
      }
    } else {
      final postUrl = Uri.parse('$_baseUrl/library-entries');

      final body = {
        'data': {
          'type': 'libraryEntries',
          'attributes': {
            'status': toKitsuStatus(status),
            'progress': progress,
            'ratingTwenty': ?kitsuScore,
          },
          'relationships': {
            'user': {
              'data': {'type': 'users', 'id': userId},
            },
            kind: {
              'data': {'type': kind, 'id': mediaIdStr},
            },
          },
        },
      };

      final resp = await _post(
        postUrl,
        headers: _headers(),
        body: jsonEncode(body),
      );
      if (resp.statusCode != 201) {
        throw Exception('Failed to create Kitsu entry: ${resp.body}');
      }
    }
  }

  Future<void> removeItem({required int id, required MediaType type}) async {
    if (!isAuthenticated) throw Exception('Kitsu is not authenticated');

    final userId = await fetchUserId();
    if (userId == null) throw Exception('Could not fetch Kitsu user id');

    final idParam = type == MediaType.anime ? 'animeId' : 'mangaId';
    final checkUrl = Uri.parse(
      '$_baseUrl/library-entries?filter[userId]=$userId&filter[$idParam]=$id',
    );
    final checkResp = await http.get(checkUrl, headers: _headers());
    if (checkResp.statusCode != 200) {
      throw Exception('Failed to find Kitsu library entry: ${checkResp.body}');
    }

    final data = jsonDecode(checkResp.body) as Map<String, dynamic>;
    final entries = (data['data'] as List<dynamic>?) ?? [];
    for (final entry in entries) {
      final entryId = entry['id'] as String?;
      if (entryId == null || entryId.isEmpty) continue;
      final resp = await http.delete(
        Uri.parse('$_baseUrl/library-entries/$entryId'),
        headers: _headers(),
      );
      if (resp.statusCode != 200 && resp.statusCode != 204) {
        throw Exception('Failed to remove Kitsu entry: ${resp.body}');
      }
    }
  }

  Future<List<MediaItem>> search(String query, MediaType type) async {
    final kind = type == MediaType.anime ? 'anime' : 'manga';
    final url = Uri.parse(
      '$_baseUrl/$kind?filter[text]=${Uri.encodeComponent(query)}&page[limit]=20',
    );
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode != 200) return [];

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>?) ?? [];

    return list.map((item) {
      final attrs = (item['attributes'] as Map<String, dynamic>?) ?? {};
      final posterMap = (attrs['posterImage'] as Map<String, dynamic>?) ?? {};
      final poster =
          (posterMap['large'] as String?) ??
          (posterMap['medium'] as String?) ??
          '';

      return MediaItem(
        id: int.tryParse(item['id'] as String) ?? 0,
        title: (attrs['canonicalTitle'] as String?) ?? 'Unknown',
        status: 'plan_to_watch',
        score: 0,
        progress: 0,
        totalProgress: type == MediaType.anime
            ? (attrs['episodeCount'] as num?)?.toInt()
            : (attrs['chapterCount'] as num?)?.toInt(),
        posterImage: poster,
        service: ServiceType.kitsu,
        mediaType: type,
      );
    }).toList();
  }

  Future<int?> findMediaIdByMalId(int malId, MediaType type) async {
    if (malId <= 0) return null;
    final kind = type == MediaType.anime ? 'anime' : 'manga';
    try {
      final url = Uri.parse(
        '$_baseUrl/mappings?filter[externalSite]=myanimelist/$kind&filter[externalId]=$malId&include=item',
      );
      final resp = await http
          .get(url, headers: _headers())
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final included = (data['included'] as List<dynamic>?) ?? [];
        for (final inc in included) {
          if (inc['type'] == kind) {
            final id = int.tryParse(inc['id'] as String);
            if (id != null && id > 0) return id;
          }
        }
        final list = (data['data'] as List<dynamic>?) ?? [];
        for (final item in list) {
          final relItem = item['relationships']?['item']?['data'];
          if (relItem != null && relItem['type'] == kind) {
            final id = int.tryParse(relItem['id'] as String);
            if (id != null && id > 0) return id;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<int?> findMalIdByKitsuId(int kitsuId, MediaType type) async {
    if (kitsuId <= 0) return null;
    final kind = type == MediaType.anime ? 'anime' : 'manga';
    try {
      final url = Uri.parse('$_baseUrl/$kind/$kitsuId/mappings');
      final resp = await http
          .get(url, headers: _headers())
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>?) ?? [];
        for (final item in list) {
          final attrs = (item['attributes'] as Map<String, dynamic>?) ?? {};
          final site = attrs['externalSite']?.toString() ?? '';
          if (site.startsWith('myanimelist')) {
            final extId = attrs['externalId']?.toString();
            final parsed = int.tryParse(extId ?? '');
            if (parsed != null && parsed > 0) return parsed;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
