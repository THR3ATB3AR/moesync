import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'oauth_service.dart';
import 'storage_service.dart';

class SimklService {
  final StorageService _storage;
  final OAuthService _oauth;
  final http.Client? client;
  static const _baseUrl = 'https://api.simkl.com';

  List<MediaItem>? _cachedAnimeList;
  String? _lastActivitiesAnimeAll;

  Future<void> _postQueue = Future.value();
  DateTime _lastPostTime = DateTime.fromMillisecondsSinceEpoch(0);
  Duration postRateLimit = const Duration(milliseconds: 1100);

  final Map<int, int?> _malIdCache = {};

  SimklService(this._storage, {this.client, OAuthService? oauth})
    : _oauth = oauth ?? OAuthService(_storage);

  ServiceCredentials get credentials =>
      _storage.getCredentials(ServiceType.simkl);

  bool get isAuthenticated =>
      credentials.accessToken != null && credentials.accessToken!.isNotEmpty;

  void clearCache() {
    _cachedAnimeList = null;
    _lastActivitiesAnimeAll = null;
    _malIdCache.clear();
  }

  @visibleForTesting
  List<MediaItem>? get cachedAnimeList => _cachedAnimeList;

  @visibleForTesting
  String? get lastActivitiesAnimeAll => _lastActivitiesAnimeAll;

  Map<String, String> _headers() {
    final credClientId = credentials.clientId;
    final clientId = (credClientId != null && credClientId.isNotEmpty)
        ? credClientId
        : StorageService.defaultSimklClientId;
    final headers = <String, String>{
      'simkl-api-key': clientId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'MoeSync/1.0',
      'app-name': 'MoeSync',
      'app-version': '1.0',
    };
    if (isAuthenticated) {
      headers['Authorization'] = 'Bearer ${credentials.accessToken}';
    }
    return headers;
  }

  Future<http.Response> _rawGet(Uri url, {Map<String, String>? headers}) {
    final c = client;
    final f = c != null
        ? c.get(url, headers: headers)
        : http.get(url, headers: headers);
    return f.timeout(const Duration(seconds: 12));
  }

  Future<http.Response> _rawPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final c = client;
    final f = c != null
        ? c.post(url, headers: headers, body: body)
        : http.post(url, headers: headers, body: body);
    return f.timeout(const Duration(seconds: 15));
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() requestFn, {
    int maxRetries = 2,
    String action = 'Simkl request',
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      http.Response resp;
      try {
        resp = await requestFn();
      } catch (e) {
        if (attempt >= maxRetries) rethrow;
        final backoff = Duration(milliseconds: 1000 * attempt);
        debugPrint(
          '$action network error: $e. Retrying in ${backoff.inMilliseconds}ms...',
        );
        await Future.delayed(backoff);
        continue;
      }

      if (resp.statusCode == 429) {
        if (attempt >= maxRetries) {
          throw Exception(
            'Simkl rate limit exceeded (429) after $maxRetries attempts: ${resp.body}',
          );
        }
        int delaySeconds = 2 * attempt;
        final retryAfterHeader = resp.headers['retry-after'];
        if (retryAfterHeader != null) {
          final parsed = int.tryParse(retryAfterHeader);
          if (parsed != null && parsed >= 0) {
            delaySeconds = parsed;
          }
        }
        if (delaySeconds > 8) {
          throw Exception(
            'Simkl rate limit exceeded (429, Retry-After: ${delaySeconds}s). Proszę odczekać chwilę.',
          );
        }
        debugPrint(
          'Simkl 429 Too Many Requests for $action. Backing off for ${delaySeconds}s (attempt $attempt/$maxRetries)...',
        );
        await Future.delayed(Duration(seconds: delaySeconds));
        continue;
      }

      if (resp.statusCode >= 500 && resp.statusCode <= 504) {
        if (attempt >= maxRetries) {
          return resp;
        }
        final backoff = Duration(milliseconds: 1500 * attempt);
        debugPrint(
          'Simkl ${resp.statusCode} server error for $action. Retrying in ${backoff.inMilliseconds}ms...',
        );
        await Future.delayed(backoff);
        continue;
      }

      return resp;
    }
  }

  Future<void> ensureValidToken() async {
    final creds = credentials;
    final refreshToken = creds.refreshToken;
    final expiresAt = creds.expiresAt;
    if (refreshToken == null || refreshToken.isEmpty || expiresAt == null) {
      return;
    }

    if (DateTime.now().isAfter(
      expiresAt.subtract(const Duration(minutes: 5)),
    )) {
      await _oauth.refreshSimklToken();
    }
  }

  Future<http.Response> _sendAuthenticated(
    Future<http.Response> Function(Map<String, String> headers) makeRequest, {
    required String action,
  }) async {
    try {
      await ensureValidToken();
    } catch (e) {
      throw Exception('Simkl session expired. Please log in again: $e');
    }
    final accessToken = credentials.accessToken;
    var resp = await _sendWithRetry(
      () => makeRequest(_headers()),
      action: action,
    );

    if (resp.statusCode == 401 &&
        credentials.refreshToken?.isNotEmpty == true) {
      if (credentials.accessToken == accessToken) {
        try {
          await _oauth.refreshSimklToken();
        } catch (e) {
          throw Exception('Simkl session expired. Please log in again: $e');
        }
      }
      resp = await _sendWithRetry(
        () => makeRequest(_headers()),
        action: action,
      );
    }

    return resp;
  }

  Future<http.Response> _get(Uri url, {String action = 'GET'}) {
    return _sendAuthenticated(
      (headers) => _rawGet(url, headers: headers),
      action: action,
    );
  }

  Future<http.Response> _rateLimitedPost(
    Uri url, {
    Object? body,
    String action = 'POST',
  }) {
    final completer = Completer<http.Response>();
    _postQueue = _postQueue.then((_) async {
      try {
        final now = DateTime.now();
        final elapsed = now.difference(_lastPostTime);
        if (elapsed < postRateLimit) {
          await Future.delayed(postRateLimit - elapsed);
        }
        final resp = await _sendAuthenticated(
          (headers) => _rawPost(url, headers: headers, body: body),
          action: action,
        );
        _lastPostTime = DateTime.now();
        completer.complete(resp);
      } catch (e, st) {
        _lastPostTime = DateTime.now();
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  static String normalizeStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'watching':
        return 'watching';
      case 'completed':
        return 'completed';
      case 'hold':
      case 'on_hold':
      case 'paused':
        return 'on_hold';
      case 'dropped':
        return 'dropped';
      case 'plantowatch':
      case 'plan_to_watch':
        return 'plan_to_watch';
      default:
        return 'plan_to_watch';
    }
  }

  static String toSimklStatus(String normalized) {
    switch (normalized.toLowerCase()) {
      case 'watching':
      case 'reading':
        return 'watching';
      case 'completed':
        return 'completed';
      case 'on_hold':
        return 'hold';
      case 'dropped':
        return 'dropped';
      case 'plan_to_watch':
      case 'plan_to_read':
      default:
        return 'plantowatch';
    }
  }

  Future<List<MediaItem>> fetchList(
    MediaType type, {
    String? status,
    int limit = 0,
    bool forceRefresh = false,
  }) async {
    if (!isAuthenticated) return [];
    if (type != MediaType.anime) return [];

    String? currentAnimeAll;
    try {
      final actResp = await _get(
        Uri.parse('$_baseUrl/sync/activities'),
        action: 'Simkl activities check',
      );
      if (actResp.statusCode == 200) {
        final actData = jsonDecode(actResp.body) as Map<String, dynamic>;
        final animeAct = actData['anime'] as Map<String, dynamic>?;
        currentAnimeAll =
            (animeAct?['all'] as String?) ?? (actData['all'] as String?);
      }
    } catch (e) {
      debugPrint('Simkl activities check error: $e');
      if (e.toString().contains('Simkl session expired')) {
        rethrow;
      }
      if (_cachedAnimeList != null && _cachedAnimeList!.isNotEmpty) {
        debugPrint(
          'Simkl activities failed; returning ${_cachedAnimeList!.length} cached items.',
        );
        return _filterByStatus(_cachedAnimeList!, status);
      }
      if (e.toString().contains('429')) {
        rethrow;
      }
    }

    if (!forceRefresh &&
        _cachedAnimeList != null &&
        _lastActivitiesAnimeAll != null &&
        currentAnimeAll != null &&
        currentAnimeAll == _lastActivitiesAnimeAll) {
      debugPrint(
        'Simkl: activities unchanged ($currentAnimeAll). Returning ${_cachedAnimeList!.length} cached items.',
      );
      return _filterByStatus(_cachedAnimeList!, status);
    }

    final urlStr = '$_baseUrl/sync/all-items/anime';
    final resp = await _get(Uri.parse(urlStr), action: 'Simkl fetch all items');

    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch Simkl list: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final animeList = (data['anime'] as List<dynamic>?) ?? [];

    final results = <MediaItem>[];
    for (final item in animeList) {
      final show = (item['show'] as Map<String, dynamic>?) ?? {};
      final ids = (show['ids'] as Map<String, dynamic>?) ?? {};
      final simklId = (ids['simkl'] as num?)?.toInt() ?? 0;
      final malIdRaw = ids['mal'];
      final malId = malIdRaw != null ? int.tryParse(malIdRaw.toString()) : null;
      final totalFromItem = (item['total_episodes_count'] as num?)?.toInt();
      final totalFromShow = (show['total_episodes'] as num?)?.toInt();
      final totalEpisodes = (totalFromItem != null && totalFromItem > 0)
          ? totalFromItem
          : (totalFromShow != null && totalFromShow > 0 ? totalFromShow : null);
      final title = (show['title'] as String?) ?? 'Unknown';

      final posterCode = show['poster'] as String?;
      final poster = posterCode != null && posterCode.isNotEmpty
          ? 'https://simkl.in/posters/${posterCode}_m.jpg'
          : '';

      final rawStatus = (item['status'] as String?) ?? 'plantowatch';
      final score = (item['user_rating'] as num?)?.toInt() ?? 0;
      final progress = (item['watched_episodes_count'] as num?)?.toInt() ?? 0;

      results.add(
        MediaItem(
          id: simklId,
          malId: malId,
          title: title,
          status: normalizeStatus(rawStatus),
          originalStatus: rawStatus,
          score: score,
          progress: progress,
          totalProgress: totalEpisodes,
          posterImage: poster,
          service: ServiceType.simkl,
          mediaType: type,
        ),
      );
    }

    _cachedAnimeList = results;
    _lastActivitiesAnimeAll = currentAnimeAll;

    return _filterByStatus(results, status);
  }

  List<MediaItem> _filterByStatus(List<MediaItem> items, String? status) {
    if (status == null || status.isEmpty || status.toLowerCase() == 'all') {
      return items;
    }
    final normalized = normalizeStatus(status);
    return items.where((item) => item.status == normalized).toList();
  }

  Future<void> updateItem({
    required int id,
    int? malId,
    String? title,
    required MediaType type,
    required String status,
    required int score,
    required int progress,
    int? oldProgress,
  }) async {
    if (!isAuthenticated) throw Exception('Simkl is not authenticated');

    final targetStatus = toSimklStatus(status);
    final ids = <String, dynamic>{};
    if (id > 0) {
      ids['simkl'] = id;
    }
    if (malId != null && malId > 0) {
      ids['mal'] = malId.toString();
    }

    final showData = <String, dynamic>{'ids': ids};
    if (title != null && title.isNotEmpty) {
      showData['title'] = title;
    }

    if (oldProgress != null && progress < oldProgress) {
      final episodesToRemove = <Map<String, dynamic>>[];
      for (int ep = progress + 1; ep <= oldProgress; ep++) {
        episodesToRemove.add({'number': ep});
      }
      if (episodesToRemove.isNotEmpty) {
        try {
          final removeResp = await _rateLimitedPost(
            Uri.parse('$_baseUrl/sync/history/remove'),
            body: jsonEncode({
              'shows': [
                {...showData, 'episodes': episodesToRemove},
              ],
            }),
            action: 'Simkl unmark episodes',
          );
          _checkResponse(removeResp, 'Simkl unmark episodes');
        } catch (e) {
          debugPrint('Simkl history/remove error: $e');
        }
      }
    }

    if (targetStatus == 'completed') {
      final historyShow = <String, dynamic>{...showData, 'status': 'completed'};
      if (score > 0) {
        historyShow['rating'] = score.clamp(1, 10);
      }
      final historyResp = await _rateLimitedPost(
        Uri.parse('$_baseUrl/sync/history'),
        body: jsonEncode({
          'shows': [historyShow],
        }),
        action: 'Simkl mark completed',
      );
      _checkResponse(historyResp, 'Simkl mark completed');
    } else if (progress > 0) {
      final episodesList = <Map<String, dynamic>>[];
      for (int i = 1; i <= progress; i++) {
        episodesList.add({'number': i});
      }

      final historyShow = <String, dynamic>{
        ...showData,
        'status': targetStatus,
        'episodes': episodesList,
      };
      if (score > 0) {
        historyShow['rating'] = score.clamp(1, 10);
      }

      final historyResp = await _rateLimitedPost(
        Uri.parse('$_baseUrl/sync/history'),
        body: jsonEncode({
          'shows': [historyShow],
        }),
        action: 'Simkl mark episodes',
      );
      _checkResponse(historyResp, 'Simkl mark episodes');

      if (targetStatus != 'watching') {
        final addResp = await _rateLimitedPost(
          Uri.parse('$_baseUrl/sync/add-to-list'),
          body: jsonEncode({
            'to': targetStatus,
            'shows': [
              {...showData, 'to': targetStatus},
            ],
          }),
          action: 'Simkl add-to-list status',
        );
        _checkResponse(addResp, 'Simkl add-to-list status');
      }
    } else {
      final addResp = await _rateLimitedPost(
        Uri.parse('$_baseUrl/sync/add-to-list'),
        body: jsonEncode({
          'to': targetStatus,
          'shows': [
            {...showData, 'to': targetStatus},
          ],
        }),
        action: 'Simkl add-to-list status',
      );
      _checkResponse(addResp, 'Simkl add-to-list status');

      if (score > 0) {
        final ratingResp = await _rateLimitedPost(
          Uri.parse('$_baseUrl/sync/ratings'),
          body: jsonEncode({
            'shows': [
              {...showData, 'rating': score.clamp(1, 10)},
            ],
          }),
          action: 'Simkl set rating',
        );
        _checkResponse(ratingResp, 'Simkl set rating');
      }
    }

    _lastActivitiesAnimeAll = null;
    if (_cachedAnimeList != null) {
      final idx = _cachedAnimeList!.indexWhere(
        (item) =>
            (id > 0 && item.id == id) ||
            (malId != null && malId > 0 && item.malId == malId),
      );
      if (idx != -1) {
        final old = _cachedAnimeList![idx];
        _cachedAnimeList![idx] = old.copyWith(
          status: normalizeStatus(status),
          originalStatus: targetStatus,
          score: score,
          progress: progress,
        );
      }
    }
  }

  Future<void> removeItem({
    required int id,
    int? malId,
    required String title,
  }) async {
    if (!isAuthenticated) throw Exception('Simkl is not authenticated');
    if (id <= 0 && (malId == null || malId <= 0) && title.trim().isEmpty) {
      throw ArgumentError('A Simkl ID, MAL ID, or title is required.');
    }

    final ids = <String, dynamic>{
      if (id > 0) 'simkl': id,
      if (malId != null && malId > 0) 'mal': malId.toString(),
    };
    final show = <String, dynamic>{
      if (title.trim().isNotEmpty) 'title': title,
      if (ids.isNotEmpty) 'ids': ids,
    };
    final resp = await _rateLimitedPost(
      Uri.parse('$_baseUrl/sync/remove-from-list'),
      body: jsonEncode({
        'shows': [show],
      }),
      action: 'Simkl remove from list',
    );
    _checkResponse(resp, 'Simkl remove from list');

    _lastActivitiesAnimeAll = null;
    _cachedAnimeList?.removeWhere(
      (item) =>
          (id > 0 && item.id == id) ||
          (malId != null && malId > 0 && item.malId == malId),
    );
  }

  void _checkResponse(http.Response resp, String action) {
    if (resp.statusCode == 200 || resp.statusCode == 201) return;

    if (resp.statusCode == 403 && resp.body.contains('insufficient_scope')) {
      throw Exception(
        'Simkl token lacks write permissions. Please disconnect and reconnect Simkl in Settings to authorize write access.',
      );
    }

    if (resp.statusCode == 429) {
      throw Exception(
        'Simkl rate limit exceeded (429) during $action. Please try again later.',
      );
    }

    throw Exception('Failed $action (${resp.statusCode}): ${resp.body}');
  }

  Future<List<MediaItem>> search(String query, MediaType type) async {
    final clientId =
        credentials.clientId ?? StorageService.defaultSimklClientId;
    final url = Uri.parse(
      '$_baseUrl/search/anime?q=${Uri.encodeComponent(query)}&client_id=$clientId',
    );
    final resp = await _get(url, action: 'Simkl search');
    if (resp.statusCode != 200) return [];

    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((item) {
      final ids = (item['ids'] as Map<String, dynamic>?) ?? {};
      final posterCode = item['poster'] as String?;
      final poster = posterCode != null && posterCode.isNotEmpty
          ? 'https://simkl.in/posters/${posterCode}_m.jpg'
          : '';

      return MediaItem(
        id: (ids['simkl'] as num?)?.toInt() ?? 0,
        title: (item['title'] as String?) ?? 'Unknown',
        status: 'plan_to_watch',
        score: 0,
        progress: 0,
        posterImage: poster,
        service: ServiceType.simkl,
        mediaType: type,
      );
    }).toList();
  }

  Future<int?> findMediaIdByMalId(int malId) async {
    if (malId <= 0) return null;
    if (_malIdCache.containsKey(malId)) {
      return _malIdCache[malId];
    }
    try {
      final credClientId = credentials.clientId;
      final clientId = (credClientId != null && credClientId.isNotEmpty)
          ? credClientId
          : StorageService.defaultSimklClientId;
      final url = Uri.parse(
        '$_baseUrl/search/id?mal=$malId&client_id=$clientId',
      );
      final resp = await _get(
        url,
        action: 'Simkl search/id',
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first as Map<String, dynamic>;
          final ids = (first['ids'] as Map<String, dynamic>?) ?? {};
          final simklId = (ids['simkl'] as num?)?.toInt();
          if (simklId != null && simklId > 0) {
            _malIdCache[malId] = simklId;
            return simklId;
          }
        }
        _malIdCache[malId] = null;
      } else if (resp.statusCode == 404) {
        _malIdCache[malId] = null;
      }
    } catch (e) {
      debugPrint('Simkl findMediaIdByMalId error for MAL $malId: $e');
    }
    return null;
  }
}
