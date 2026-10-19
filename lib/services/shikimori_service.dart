import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'oauth_service.dart';
import 'storage_service.dart';

class ShikimoriService {
  final StorageService _storage;
  final OAuthService _oauth;
  static const _baseUrl = 'https://shikimori.io/api';

  ShikimoriService(this._storage, {OAuthService? oauth})
    : _oauth = oauth ?? OAuthService(_storage);

  ServiceCredentials get credentials =>
      _storage.getCredentials(ServiceType.shikimori);

  bool get isAuthenticated =>
      credentials.accessToken != null &&
      credentials.accessToken!.isNotEmpty &&
      (credentials.isConnected || credentials.refreshToken != null);

  Map<String, String> _headers() {
    final headers = <String, String>{
      'User-Agent': 'anisync-flutter',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (isAuthenticated) {
      headers['Authorization'] = 'Bearer ${credentials.accessToken}';
    }
    return headers;
  }

  Future<void> ensureValidToken() async {
    final creds = credentials;
    final refresh = creds.refreshToken;
    if (refresh == null || refresh.isEmpty) return;

    if (creds.expiresAt != null) {
      final now = DateTime.now();
      if (now.isAfter(creds.expiresAt!.subtract(const Duration(minutes: 5)))) {
        try {
          await _oauth.refreshShikimoriToken();
        } catch (_) {}
      }
    }
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function(Map<String, String> headers) makeRequest,
  ) async {
    await ensureValidToken();
    var resp = await makeRequest(_headers());

    if (resp.statusCode == 401 &&
        credentials.refreshToken != null &&
        credentials.refreshToken!.isNotEmpty) {
      try {
        await _oauth.refreshShikimoriToken();
        resp = await makeRequest(_headers());
      } catch (e) {
        throw Exception('Shikimori session expired. Please log in again: $e');
      }
    }

    return resp;
  }

  static String normalizeStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'watching':
      case 'reading':
      case 'rewatching':
      case 'rereading':
        return 'watching';
      case 'completed':
        return 'completed';
      case 'on_hold':
      case 'paused':
      case 'hold':
        return 'on_hold';
      case 'dropped':
        return 'dropped';
      case 'planned':
        return 'plan_to_watch';
      default:
        return 'plan_to_watch';
    }
  }

  static String toShikimoriStatus(String normalized) {
    switch (normalized.toLowerCase()) {
      case 'watching':
      case 'reading':
        return 'watching';
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

  Future<int?> fetchUserId() async {
    if (!isAuthenticated) return null;

    final cachedId = int.tryParse(credentials.userId ?? '');
    if (cachedId != null && cachedId > 0) {
      return cachedId;
    }

    final url = Uri.parse('$_baseUrl/users/whoami');
    final resp = await _sendRequest(
      (headers) => http.get(url, headers: headers),
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to authenticate with Shikimori (${resp.statusCode}): ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final id = (data['id'] as num?)?.toInt();
    if (id == null || id <= 0) {
      throw Exception(
        'Could not determine Shikimori user ID from API response',
      );
    }

    await _storage.saveCredentials(
      ServiceType.shikimori,
      credentials.copyWith(userId: id.toString()),
    );
    return id;
  }

  Future<List<MediaItem>> fetchList(
    MediaType type, {
    String? status,
    int limit = 0,
  }) async {
    if (!isAuthenticated) return [];

    final userId = await fetchUserId();
    if (userId == null) {
      throw Exception('Shikimori user ID could not be determined');
    }

    final endpoint = type == MediaType.anime ? 'anime_rates' : 'manga_rates';
    var urlStr = '$_baseUrl/users/$userId/$endpoint?limit=5000';
    if (status != null && status.isNotEmpty) {
      urlStr += '&status=${toShikimoriStatus(status)}';
    }

    final resp = await _sendRequest(
      (headers) => http.get(Uri.parse(urlStr), headers: headers),
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch Shikimori list (${resp.statusCode}): ${resp.body}',
      );
    }

    final list = jsonDecode(resp.body) as List<dynamic>;
    final results = <MediaItem>[];

    String? firstTitle(dynamic value) {
      if (value is String && value.isNotEmpty) return value;
      if (value is List) {
        for (final item in value) {
          if (item is String && item.isNotEmpty) return item;
        }
      }
      return null;
    }

    for (final item in list) {
      final rate = item as Map<String, dynamic>;
      final target =
          (type == MediaType.anime ? rate['anime'] : rate['manga'])
              as Map<String, dynamic>? ??
          {};

      final id =
          (target['id'] as num?)?.toInt() ??
          (rate['target_id'] as num?)?.toInt() ??
          0;
      var title = (target['name'] as String?) ?? '';
      if (title.isEmpty) {
        title = (target['russian'] as String?) ?? 'Unknown';
      }

      final imageMap = (target['image'] as Map<String, dynamic>?) ?? {};
      var poster = (imageMap['original'] as String?) ?? '';
      if (poster.isNotEmpty && !poster.startsWith('http')) {
        poster = 'https://shikimori.io$poster';
      }

      final rawStatus = (rate['status'] as String?) ?? 'planned';
      final score = (rate['score'] as num?)?.toInt() ?? 0;
      final progress = type == MediaType.anime
          ? (rate['episodes'] as num?)?.toInt() ?? 0
          : (rate['chapters'] as num?)?.toInt() ?? 0;
      final totalProgress = type == MediaType.anime
          ? (target['episodes'] as num?)?.toInt()
          : (target['chapters'] as num?)?.toInt();

      results.add(
        MediaItem(
          id: id,
          title: title,
          englishTitle: firstTitle(target['english']),
          japaneseTitle: firstTitle(target['japanese']),
          romajiTitle: target['name'] as String?,
          alternativeTitles:
              (target['synonyms'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList() ??
              const [],
          status: normalizeStatus(rawStatus),
          originalStatus: rawStatus,
          score: score,
          progress: progress,
          totalProgress: totalProgress,
          posterImage: poster,
          service: ServiceType.shikimori,
          mediaType: type,
        ),
      );
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
    if (!isAuthenticated) throw Exception('Shikimori is not authenticated');

    final userId = await fetchUserId();
    if (userId == null) throw Exception('Could not fetch Shikimori user id');

    final targetType = type == MediaType.anime ? 'Anime' : 'Manga';
    final checkUrl = Uri.parse(
      '$_baseUrl/v2/user_rates?user_id=$userId&target_id=$id&target_type=$targetType',
    );

    final checkResp = await _sendRequest(
      (headers) => http.get(checkUrl, headers: headers),
    );
    final existingRates = checkResp.statusCode == 200
        ? (jsonDecode(checkResp.body) as List<dynamic>)
        : [];

    final payload = <String, dynamic>{
      'status': toShikimoriStatus(status),
      'score': score,
      if (type == MediaType.anime)
        'episodes': progress
      else
        'chapters': progress,
    };

    if (existingRates.isNotEmpty) {
      final rateId = existingRates.first['id'] as int;
      final patchUrl = Uri.parse('$_baseUrl/v2/user_rates/$rateId');
      final resp = await _sendRequest(
        (headers) => http.patch(
          patchUrl,
          headers: headers,
          body: jsonEncode({'user_rate': payload}),
        ),
      );
      if (resp.statusCode != 200) {
        throw Exception(
          'Failed to update Shikimori entry (${resp.statusCode}): ${resp.body}',
        );
      }
    } else {
      payload['user_id'] = userId;
      payload['target_id'] = id;
      payload['target_type'] = targetType;

      final postUrl = Uri.parse('$_baseUrl/v2/user_rates');
      final resp = await _sendRequest(
        (headers) => http.post(
          postUrl,
          headers: headers,
          body: jsonEncode({'user_rate': payload}),
        ),
      );
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        throw Exception(
          'Failed to create Shikimori entry (${resp.statusCode}): ${resp.body}',
        );
      }
    }
  }

  Future<List<MediaItem>> search(String query, MediaType type) async {
    final endpoint = type == MediaType.anime ? 'animes' : 'mangas';
    final url = Uri.parse(
      '$_baseUrl/$endpoint?search=${Uri.encodeComponent(query)}&limit=20',
    );
    final resp = await _sendRequest(
      (headers) => http.get(url, headers: headers),
    );
    if (resp.statusCode != 200) return [];

    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((item) {
      final m = item as Map<String, dynamic>;
      final img = (m['image'] as Map<String, dynamic>?) ?? {};
      var poster = (img['original'] as String?) ?? '';
      if (poster.isNotEmpty && !poster.startsWith('http')) {
        poster = 'https://shikimori.io$poster';
      }

      return MediaItem(
        id: (m['id'] as num).toInt(),
        title: (m['name'] as String?) ?? (m['russian'] as String?) ?? 'Unknown',
        status: 'plan_to_watch',
        score: 0,
        progress: 0,
        totalProgress: type == MediaType.anime
            ? (m['episodes'] as num?)?.toInt()
            : (m['chapters'] as num?)?.toInt(),
        posterImage: poster,
        service: ServiceType.shikimori,
        mediaType: type,
      );
    }).toList();
  }
}
