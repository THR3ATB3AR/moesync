import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'oauth_service.dart';
import 'storage_service.dart';

class MangaBakaService {
  final StorageService _storage;
  final OAuthService _oauth;
  final http.Client _client;

  static const String baseUrl = 'https://api.mangabaka.org';

  void Function(Map<String, dynamic> series)? onSeriesFetched;

  MangaBakaService(this._storage, {OAuthService? oauth, http.Client? client})
    : _oauth = oauth ?? OAuthService(_storage),
      _client = client ?? http.Client();

  bool get isAuthenticated {
    final creds = _storage.getCredentials(ServiceType.mangabaka);
    return creds.isConnected || (creds.accessToken?.isNotEmpty ?? false);
  }

  Map<String, String> _buildHeaders() {
    final creds = _storage.getCredentials(ServiceType.mangabaka);
    final token = creds.accessToken?.trim() ?? '';
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'MoeSync/1.0.0',
    };

    if (token.isNotEmpty) {
      if (token.startsWith('mb-')) {
        headers['x-api-key'] = token;
      } else {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<void> ensureValidToken() async {
    final creds = _storage.getCredentials(ServiceType.mangabaka);
    final refresh = creds.refreshToken;
    if (refresh == null || refresh.isEmpty) return;

    if (creds.expiresAt != null) {
      final now = DateTime.now();
      if (now.isAfter(creds.expiresAt!.subtract(const Duration(minutes: 5)))) {
        try {
          await _oauth.refreshMangaBakaToken();
        } catch (_) {}
      }
    }
  }

  Future<http.Response> _sendAuthedRequest(
    Future<http.Response> Function(Map<String, String> headers) makeRequest,
  ) async {
    await ensureValidToken();
    var resp = await makeRequest(_buildHeaders());

    if (resp.statusCode == 401 &&
        _storage
                .getCredentials(ServiceType.mangabaka)
                .refreshToken
                ?.isNotEmpty ==
            true) {
      try {
        await _oauth.refreshMangaBakaToken();
        resp = await makeRequest(_buildHeaders());
      } catch (e) {
        throw Exception('MangaBaka session expired. Please log in again: $e');
      }
    }

    return resp;
  }

  String normalizeStatus(String state) {
    switch (state.toLowerCase()) {
      case 'reading':
      case 'rereading':
        return 'watching';
      case 'completed':
        return 'completed';
      case 'paused':
        return 'on_hold';
      case 'dropped':
        return 'dropped';
      case 'plan_to_read':
      case 'considering':
      default:
        return 'plan_to_watch';
    }
  }

  String denormalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'watching':
      case 'reading':
        return 'reading';
      case 'completed':
        return 'completed';
      case 'on_hold':
      case 'paused':
        return 'paused';
      case 'dropped':
        return 'dropped';
      case 'plan_to_watch':
      case 'plan_to_read':
      default:
        return 'plan_to_read';
    }
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
      throw Exception('MangaBaka is not authenticated');
    }

    final items = <MediaItem>[];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final uri = Uri.parse(
        '$baseUrl/v2/my/library',
      ).replace(queryParameters: {'page': '$page', 'limit': '50'});

      final response = await _sendAuthedRequest(
        (headers) => _client.get(uri, headers: headers),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch MangaBaka library (${response.statusCode}): ${response.body}',
        );
      }

      final json = jsonDecode(response.body);
      if (json is! Map) return items;
      final data = json['data'] as List<dynamic>? ?? [];

      for (final raw in data) {
        if (raw is! Map) continue;
        final entry = raw['entry'] is Map ? raw['entry'] as Map : {};
        final series = raw['series'] is Map ? raw['series'] as Map : {};

        final seriesId =
            _asInt(entry['series_id']) ??
            _asInt(series['id']) ??
            _asInt(entry['id']) ??
            0;

        if (seriesId <= 0) continue;

        final rawState = entry['state']?.toString() ?? 'reading';
        final normalized = normalizeStatus(rawState);

        if (status != null && status != 'all' && normalized != status) {
          continue;
        }

        final rawRating =
            (entry['rating'] as num?)?.toDouble() ??
            double.tryParse(entry['rating']?.toString() ?? '');
        final score = rawRating != null && rawRating > 0
            ? (rawRating / 10).round()
            : 0;

        final progress = _asInt(entry['progress_chapter']) ?? 0;

        final poster = _extractPoster(series['cover']);
        final title = _extractTitle(series, seriesId);
        final malId = _extractMalId(series['source']);
        final totalChapters =
            _asInt(series['total_chapters']) ??
            _asInt(series['available_chapters']);

        if (series.isNotEmpty) {
          try {
            onSeriesFetched?.call(Map<String, dynamic>.from(series));
          } catch (_) {}
        }

        items.add(
          MediaItem(
            id: seriesId,
            malId: malId,
            title: title,
            status: normalized,
            score: score,
            progress: progress,
            totalProgress: totalChapters,
            posterImage: poster,
            service: ServiceType.mangabaka,
            mediaType: MediaType.manga,
            originalStatus: rawState,
          ),
        );

        if (limit != null && items.length >= limit) {
          return items;
        }
      }

      final pagination = json['pagination'];
      if (pagination is Map) {
        final next = pagination['next'];
        final totalCount = (pagination['count'] as num?)?.toInt();
        final limitParam = (pagination['limit'] as num?)?.toInt() ?? 50;

        if (next == null ||
            data.isEmpty ||
            (totalCount != null && page * limitParam >= totalCount)) {
          hasMore = false;
        } else {
          page++;
        }
      } else {
        hasMore = false;
      }
    }

    return items;
  }

  String _extractPoster(dynamic cover) {
    if (cover == null) return '';
    if (cover is String) return cover;
    if (cover is Map) {
      for (final key in ['raw', 'x350', 'x250', 'x150', 'x300']) {
        final val = cover[key];
        if (val is String && val.isNotEmpty) {
          return val;
        }
        if (val is Map) {
          final nested = val['url'] ?? val['x1'];
          if (nested is String && nested.isNotEmpty) {
            return nested;
          }
        }
      }
    }
    return '';
  }

  String _extractTitle(dynamic rawSeries, int seriesId) {
    if (rawSeries is! Map) return 'Manga #$seriesId';

    final directTitle = rawSeries['title'];
    if (directTitle is String && directTitle.isNotEmpty) {
      return directTitle;
    }

    final titles = rawSeries['titles'];
    if (titles is List && titles.isNotEmpty) {
      for (final t in titles) {
        if (t is Map && t['is_primary'] == true) {
          final text = t['title'];
          if (text is String && text.isNotEmpty) return text;
        }
      }
      for (final t in titles) {
        if (t is Map) {
          final text = t['title'];
          if (text is String && text.isNotEmpty) return text;
        }
      }
    }

    if (titles is Map) {
      for (final key in ['canonical', 'english', 'romanized']) {
        final text = titles[key];
        if (text is String && text.isNotEmpty) return text;
      }
    }

    final romanized = rawSeries['romanized_title'];
    if (romanized is String && romanized.isNotEmpty) return romanized;

    final native = rawSeries['native_title'];
    if (native is String && native.isNotEmpty) return native;

    return 'Manga #$seriesId';
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int? _extractMalId(dynamic source) {
    if (source is! Map) return null;
    final malObj = source['my_anime_list'];
    if (malObj is Map) {
      return _asInt(malObj['id']);
    } else if (malObj is num) {
      return malObj.toInt();
    } else if (malObj is String) {
      return int.tryParse(malObj);
    }
    return null;
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
      throw Exception('MangaBaka is not authenticated');
    }

    final mbState = denormalizeStatus(status);
    final mbScore = score > 0 ? (score <= 10 ? score * 10 : score) : null;

    final body = jsonEncode({
      'state': mbState,
      'progress_chapter': progress,
      'rating': mbScore,
    });

    final putUri = Uri.parse('$baseUrl/v1/my/library/$id');
    final putResp = await _sendAuthedRequest(
      (headers) => _client.put(putUri, headers: headers, body: body),
    );

    if (putResp.statusCode == 200 ||
        putResp.statusCode == 201 ||
        putResp.statusCode == 204) {
      return;
    }

    if (putResp.statusCode == 404) {
      final postResp = await _sendAuthedRequest(
        (headers) => _client.post(putUri, headers: headers, body: body),
      );
      if (postResp.statusCode == 200 ||
          postResp.statusCode == 201 ||
          postResp.statusCode == 204) {
        return;
      }
      throw Exception(
        'Failed to create MangaBaka entry (${postResp.statusCode}): ${postResp.body}',
      );
    }

    throw Exception(
      'Failed to update MangaBaka entry (${putResp.statusCode}): ${putResp.body}',
    );
  }

  Future<void> removeItem({required int id}) async {
    if (!isAuthenticated) {
      throw Exception('MangaBaka is not authenticated');
    }

    final uri = Uri.parse('$baseUrl/v1/my/library/$id');
    final resp = await _sendAuthedRequest(
      (headers) => _client.delete(uri, headers: headers),
    );
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception(
        'Failed to remove MangaBaka entry (${resp.statusCode}): ${resp.body}',
      );
    }
    if (resp.statusCode == 200) {
      final response = jsonDecode(resp.body) as Map<String, dynamic>;
      if (response['data'] != true) {
        throw Exception('MangaBaka did not remove the library entry.');
      }
    }
  }

  Future<Map<String, dynamic>?> fetchSourceSeries(
    String sourceName,
    dynamic sourceId,
  ) async {
    try {
      final String idStr;
      if (sourceName == 'manga-updates') {
        if (sourceId is int) {
          idStr = sourceId.toRadixString(36);
        } else {
          final parsed = int.tryParse(sourceId.toString());
          idStr = parsed != null
              ? parsed.toRadixString(36)
              : sourceId.toString();
        }
      } else {
        idStr = sourceId.toString();
      }

      final uri = Uri.parse('$baseUrl/v1/source/$sourceName/$idStr');
      final resp = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(resp.body);
      if (json is! Map) return null;
      final data = json['data'];
      if (data is! Map) return null;
      final seriesList = data['series'];
      if (seriesList is List && seriesList.isNotEmpty) {
        final first = seriesList.first;
        if (first is Map) {
          final mapped = Map<String, dynamic>.from(first);
          try {
            onSeriesFetched?.call(mapped);
          } catch (_) {}
          return mapped;
        }
      }
    } catch (_) {}
    return null;
  }
}
