import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'oauth_service.dart';
import 'storage_service.dart';

class MalService {
  final StorageService _storage;
  final OAuthService _oauth;

  MalService(this._storage, {OAuthService? oauth})
    : _oauth = oauth ?? OAuthService(_storage);

  ServiceCredentials get credentials =>
      _storage.getCredentials(ServiceType.mal);

  bool get isAuthenticated =>
      credentials.accessToken != null && credentials.accessToken!.isNotEmpty;

  Map<String, String> _headers() {
    return {
      'Authorization': 'Bearer ${credentials.accessToken}',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  Future<void> ensureValidToken() async {
    final creds = credentials;
    final refresh = creds.refreshToken;
    if (refresh == null || refresh.isEmpty) return;

    if (creds.expiresAt != null) {
      final now = DateTime.now();
      if (now.isAfter(creds.expiresAt!.subtract(const Duration(minutes: 5)))) {
        try {
          await _oauth.refreshMalToken();
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
        await _oauth.refreshMalToken();
        resp = await makeRequest(_headers());
      } catch (e) {
        throw Exception('MAL session expired. Please log in again: $e');
      }
    }

    return resp;
  }

  static String normalizeStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'watching':
      case 'reading':
        return 'watching';
      case 'completed':
        return 'completed';
      case 'on_hold':
      case 'paused':
      case 'hold':
        return 'on_hold';
      case 'dropped':
        return 'dropped';
      case 'plan_to_watch':
      case 'plan_to_read':
      case 'planned':
      case 'planning':
        return 'plan_to_watch';
      default:
        return 'plan_to_watch';
    }
  }

  static String toMalStatus(String normalized, MediaType type) {
    if (type == MediaType.manga) {
      switch (normalized) {
        case 'watching':
          return 'reading';
        case 'completed':
          return 'completed';
        case 'on_hold':
          return 'on_hold';
        case 'dropped':
          return 'dropped';
        case 'plan_to_watch':
        default:
          return 'plan_to_read';
      }
    } else {
      switch (normalized) {
        case 'watching':
          return 'watching';
        case 'completed':
          return 'completed';
        case 'on_hold':
          return 'on_hold';
        case 'dropped':
          return 'dropped';
        case 'plan_to_watch':
        default:
          return 'plan_to_watch';
      }
    }
  }

  final Map<int, int> _totalProgressCache = {};

  Future<List<MediaItem>> fetchList(
    MediaType type, {
    String? status,
    int limit = 0,
  }) async {
    if (!isAuthenticated) return [];

    final endpoint = type == MediaType.anime ? 'animelist' : 'mangalist';
    final extraField = type == MediaType.anime
        ? 'num_episodes'
        : 'num_chapters';
    final extraRepeatField = type == MediaType.anime
        ? 'num_times_rewatched'
        : 'num_times_reread';
    var urlStr =
        'https://api.myanimelist.net/v2/users/@me/$endpoint?fields=list_status{status,score,num_episodes_watched,num_chapters_read,updated_at,start_date,finish_date,priority,$extraRepeatField},main_picture,alternative_titles,$extraField,start_date,created_at&limit=1000&nsfw=true';
    if (status != null && status.isNotEmpty) {
      urlStr += '&status=${toMalStatus(status, type)}';
    }

    try {
      final results = <MediaItem>[];
      String? nextUrl = urlStr;
      while (nextUrl != null && nextUrl.isNotEmpty) {
        final resp = await _sendRequest(
          (headers) => http.get(Uri.parse(nextUrl!), headers: headers),
        );
        if (resp.statusCode != 200) {
          throw Exception('Failed to fetch MAL list: ${resp.body}');
        }

        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>?) ?? [];

        for (final item in list) {
          final node = item['node'] as Map<String, dynamic>;
          final listStatus =
              (item['list_status'] as Map<String, dynamic>?) ?? {};

          final id = (node['id'] as num).toInt();
          final title = (node['title'] as String?) ?? 'Unknown';
          final alternativeTitles =
              (node['alternative_titles'] as Map<String, dynamic>?) ?? {};
          final mainPic = (node['main_picture'] as Map<String, dynamic>?) ?? {};
          final poster =
              (mainPic['large'] as String?) ??
              (mainPic['medium'] as String?) ??
              '';

          final rawStatus =
              (listStatus['status'] as String?) ?? 'plan_to_watch';
          final score = (listStatus['score'] as num?)?.toInt() ?? 0;
          final progress = type == MediaType.anime
              ? (listStatus['num_episodes_watched'] as num?)?.toInt() ?? 0
              : (listStatus['num_chapters_read'] as num?)?.toInt() ?? 0;
          final totalProgressRaw = type == MediaType.anime
              ? (node['num_episodes'] as num?)?.toInt()
              : (node['num_chapters'] as num?)?.toInt();
          final totalProgress =
              (totalProgressRaw != null && totalProgressRaw > 0)
              ? totalProgressRaw
              : null;

          if (totalProgress != null) {
            _totalProgressCache[id] = totalProgress;
          }

          final updatedAtStr = listStatus['updated_at'] as String?;
          final updatedAt = updatedAtStr != null
              ? DateTime.tryParse(updatedAtStr)
              : null;

          final startDateStr =
              (listStatus['start_date'] as String?) ??
              (node['start_date'] as String?);
          final startDate = startDateStr != null
              ? DateTime.tryParse(startDateStr)
              : null;

          final finishDateStr = listStatus['finish_date'] as String?;
          final finishDate = finishDateStr != null
              ? DateTime.tryParse(finishDateStr)
              : null;

          final priority = (listStatus['priority'] as num?)?.toInt() ?? 0;

          final repeatCount = type == MediaType.anime
              ? ((listStatus['num_times_rewatched'] as num?)?.toInt() ?? 0)
              : ((listStatus['num_times_reread'] as num?)?.toInt() ?? 0);

          final createdAtStr =
              (listStatus['created_at'] as String?) ??
              (node['created_at'] as String?);
          final createdAt = createdAtStr != null
              ? DateTime.tryParse(createdAtStr)
              : null;

          results.add(
            MediaItem(
              id: id,
              title: title,
              englishTitle: alternativeTitles['en'] as String?,
              japaneseTitle: alternativeTitles['ja'] as String?,
              romajiTitle: title,
              alternativeTitles:
                  (alternativeTitles['synonyms'] as List<dynamic>?)
                      ?.whereType<String>()
                      .toList() ??
                  const [],
              status: normalizeStatus(rawStatus),
              originalStatus: rawStatus,
              score: score,
              progress: progress,
              totalProgress: totalProgress,
              posterImage: poster,
              service: ServiceType.mal,
              mediaType: type,
              updatedAt: updatedAt,
              startDate: startDate,
              finishDate: finishDate,
              priority: priority,
              repeatCount: repeatCount,
              createdAt: createdAt,
            ),
          );
        }

        final paging = data['paging'] as Map<String, dynamic>?;
        nextUrl = (limit == 0) ? (paging?['next'] as String?) : null;
      }
      return results;
    } catch (e) {
      rethrow;
    }
  }

  Future<int?> fetchTotalProgressById(int malId, MediaType type) async {
    if (malId <= 0) return null;
    if (_totalProgressCache.containsKey(malId)) {
      return _totalProgressCache[malId];
    }
    try {
      final endpoint = type == MediaType.anime ? 'anime' : 'manga';
      final field = type == MediaType.anime ? 'num_episodes' : 'num_chapters';
      final clientId =
          credentials.clientId ?? StorageService.defaultMalClientId;
      final url = Uri.parse(
        'https://api.myanimelist.net/v2/$endpoint/$malId?fields=$field',
      );
      final headers = isAuthenticated
          ? _headers()
          : {'X-MAL-CLIENT-ID': clientId};
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final count = (data[field] as num?)?.toInt();
        if (count != null && count > 0) {
          _totalProgressCache[malId] = count;
          return count;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> updateItem({
    required int id,
    required MediaType type,
    required String status,
    required int score,
    required int progress,
  }) async {
    if (!isAuthenticated) throw Exception('MAL is not authenticated');

    final endpoint = type == MediaType.anime ? 'anime' : 'manga';
    final url = Uri.parse(
      'https://api.myanimelist.net/v2/$endpoint/$id/my_list_status',
    );

    final body = <String, String>{
      'status': toMalStatus(status, type),
      'score': score.toString(),
    };
    if (type == MediaType.anime) {
      body['num_watched_episodes'] = progress.toString();
    } else {
      body['num_chapters_read'] = progress.toString();
    }

    final resp = await _sendRequest(
      (headers) => http.patch(url, headers: headers, body: body),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Failed to update MAL entry: ${resp.body}');
    }
  }

  Future<List<MediaItem>> search(String query, MediaType type) async {
    final clientId = credentials.clientId ?? StorageService.defaultMalClientId;
    final endpoint = type == MediaType.anime ? 'anime' : 'manga';
    final url = Uri.parse(
      'https://api.myanimelist.net/v2/$endpoint?q=${Uri.encodeComponent(query)}&limit=20&fields=main_picture,alternative_titles,num_episodes,num_chapters',
    );

    final resp = await http.get(url, headers: {'X-MAL-CLIENT-ID': clientId});
    if (resp.statusCode != 200) return [];

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>?) ?? [];
    return list.map((item) {
      final node = item['node'] as Map<String, dynamic>;
      final mainPic = (node['main_picture'] as Map<String, dynamic>?) ?? {};
      final alternativeTitles =
          (node['alternative_titles'] as Map<String, dynamic>?) ?? {};
      return MediaItem(
        id: (node['id'] as num).toInt(),
        title: (node['title'] as String?) ?? 'Unknown',
        englishTitle: alternativeTitles['en'] as String?,
        japaneseTitle: alternativeTitles['ja'] as String?,
        romajiTitle: (node['title'] as String?) ?? 'Unknown',
        status: 'plan_to_watch',
        score: 0,
        progress: 0,
        totalProgress: type == MediaType.anime
            ? (node['num_episodes'] as num?)?.toInt()
            : (node['num_chapters'] as num?)?.toInt(),
        posterImage:
            (mainPic['large'] as String?) ??
            (mainPic['medium'] as String?) ??
            '',
        service: ServiceType.mal,
        mediaType: type,
      );
    }).toList();
  }
}
