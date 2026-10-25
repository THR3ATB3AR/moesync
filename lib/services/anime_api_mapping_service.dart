import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/anime_api_database.dart';
import '../models/media_item.dart';
import 'storage_service.dart';

class AnimeApiMappingService extends ChangeNotifier {
  AnimeApiMappingService(this._storage, {http.Client? client})
    : _client = client ?? http.Client();

  static final _databaseUri = Uri.parse(
    'https://raw.githubusercontent.com/nattadasu/animeApi/v3/database/animeapi.tsv',
  );
  static final _runsUri = Uri.parse(
    'https://raw.githubusercontent.com/nattadasu/animeApi/v3/database/runs.json',
  );
  static const _databaseFileName = 'animeapi-v3.tsv';
  static const _refreshInterval = Duration(days: 1);
  static const _providerForService = {
    ServiceType.mal: 'myanimelist',
    ServiceType.anilist: 'anilist',
    ServiceType.kitsu: 'kitsu',
    ServiceType.shikimori: 'shikimori',
    ServiceType.simkl: 'simkl',
  };

  final StorageService _storage;
  final http.Client _client;
  final Map<String, Map<String, int>> _idToMal = {};
  final Map<int, AnimeApiRecord> _recordsByMalId = {};

  Future<void>? _initializeFuture;
  Future<void>? _refreshFuture;
  bool _isLoaded = false;
  AnimeApiDatabaseMetadata? _metadata;

  bool get isLoaded => _isLoaded;
  int get mappingsCount => _recordsByMalId.length;
  AnimeApiDatabaseMetadata? get metadata => _metadata;

  Future<void> initialize() {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _storage.removeLegacyFribbCache();
      final file = await _databaseFile();
      if (await file.exists() && await file.length() > 0) {
        try {
          await _loadDatabase(file);
          _metadata = _storage.getAnimeApiDatabaseMetadata();
          notifyListeners();
        } catch (error) {
          debugPrint('Failed to load cached AnimeApi database: $error');
          await file.delete();
        }
      }
      if (!_isLoaded) {
        try {
          await refreshDatabase();
        } catch (error) {
          debugPrint('Failed to download initial AnimeApi database: $error');
        }
      }
    } catch (error) {
      debugPrint('Failed to initialize AnimeApi database: $error');
      _isLoaded = _recordsByMalId.isNotEmpty;
    }

    final lastDownload = _metadata?.downloadedAt;
    if (_isLoaded &&
        (lastDownload == null ||
            DateTime.now().difference(lastDownload) >= _refreshInterval)) {
      unawaited(
        refreshDatabase().catchError((Object error) {
          debugPrint('AnimeApi database auto-refresh failed: $error');
        }),
      );
    }
  }

  Future<bool> refreshMapping() async {
    try {
      await refreshDatabase();
      return true;
    } catch (error) {
      debugPrint('AnimeApi database refresh failed: $error');
      return false;
    }
  }

  Future<void> refreshDatabase() async {
    final pending = _refreshFuture;
    if (pending != null) return pending;

    final refresh = _downloadAndLoadDatabase();
    _refreshFuture = refresh;
    try {
      await refresh;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _downloadAndLoadDatabase() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final databaseFile = File('${directory.path}/$_databaseFileName');
    final temporaryFile = File('${databaseFile.path}.download');

    try {
      final request = http.Request('GET', _databaseUri)
        ..headers['User-Agent'] = 'MoeSync';
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'AnimeApi database download failed (${response.statusCode}).',
          uri: _databaseUri,
        );
      }
      await response.stream
          .timeout(const Duration(seconds: 60))
          .pipe(temporaryFile.openWrite());

      final parsed = await compute(_parseAnimeApiTsv, temporaryFile.path);
      final rows = parsed['records'] as List<Map<String, String>>;
      if (rows.isEmpty) {
        throw const FormatException('AnimeApi database contains no records.');
      }

      if (await databaseFile.exists()) {
        await databaseFile.delete();
      }
      await temporaryFile.rename(databaseFile.path);
      _installRecords(rows);

      DateTime? sourceUpdatedAt;
      try {
        sourceUpdatedAt = await _fetchSourceUpdatedAt();
      } catch (error) {
        debugPrint('Failed to fetch AnimeApi source metadata: $error');
      }
      final metadata = AnimeApiDatabaseMetadata(
        recordCount: rows.length,
        downloadedAt: DateTime.now(),
        sourceUpdatedAt: sourceUpdatedAt ?? _metadata?.sourceUpdatedAt,
      );
      await _storage.saveAnimeApiDatabaseMetadata(metadata);
      _metadata = metadata;
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
      rethrow;
    }
  }

  Future<File> _databaseFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/$_databaseFileName');
  }

  Future<void> _loadDatabase(File file) async {
    final parsed = await compute(_parseAnimeApiTsv, file.path);
    final rows = parsed['records'] as List<Map<String, String>>;
    _installRecords(rows);
    _isLoaded = rows.isNotEmpty;
    if (!_isLoaded) {
      throw const FormatException(
        'Local AnimeApi database contains no records.',
      );
    }
  }

  void _installRecords(List<Map<String, String>> rows) {
    _idToMal.clear();
    _recordsByMalId.clear();
    for (final row in rows) {
      final malId =
          int.tryParse(row['myanimelist'] ?? '') ??
          int.tryParse(row['shikimori'] ?? '');
      if (malId == null || malId <= 0) continue;
      final title = row.remove('title') ?? '';
      _recordsByMalId[malId] = AnimeApiRecord(
        title: title,
        ids: Map.unmodifiable(row),
      );
      for (final entry in row.entries) {
        _idToMal.putIfAbsent(entry.key, () => {})[entry.value] = malId;
      }
    }
  }

  Future<DateTime?> _fetchSourceUpdatedAt() async {
    final response = await _client
        .get(_runsUri, headers: const {'User-Agent': 'MoeSync'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'AnimeApi metadata request failed (${response.statusCode}).',
        uri: _runsUri,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Invalid AnimeApi build metadata.');
    }

    final successfulRuns =
        decoded
            .whereType<Map<String, dynamic>>()
            .where((run) => run['status'] == 'success')
            .toList()
          ..sort((a, b) {
            final first = DateTime.tryParse(a['timestamp'] as String? ?? '');
            final second = DateTime.tryParse(b['timestamp'] as String? ?? '');
            return (second ?? DateTime(0)).compareTo(first ?? DateTime(0));
          });
    if (successfulRuns.isEmpty) return null;
    return DateTime.tryParse(
      successfulRuns.first['timestamp'] as String? ?? '',
    );
  }

  int findMalId(ServiceType service, int id) {
    if (service == ServiceType.mal) return id;
    final provider = _providerForService[service];
    if (provider == null) return 0;
    final malId = _idToMal[provider]?[id.toString()];
    return malId ?? (service == ServiceType.shikimori ? id : 0);
  }

  Future<int> findMalIdWithFallback(ServiceType service, int id) async {
    return findMalId(service, id);
  }

  int findTargetId(int malId, ServiceType targetService) {
    if (targetService == ServiceType.mal) return malId;
    final provider = _providerForService[targetService];
    if (provider == null) return 0;
    return int.tryParse(_recordsByMalId[malId]?.ids[provider] ?? '') ??
        (targetService == ServiceType.shikimori ? malId : 0);
  }

  Future<int> findTargetIdWithFallback(
    int malId,
    ServiceType targetService,
  ) async {
    return findTargetId(malId, targetService);
  }

  int findPlatformId(int malId, String platform) {
    return int.tryParse(findPlatformValue(malId, platform) ?? '') ?? 0;
  }

  String? findPlatformValue(int malId, String platform) {
    return _recordsByMalId[malId]?.ids[platform];
  }

  String? findTitle(int malId) {
    final title = _recordsByMalId[malId]?.title;
    return title == null || title.isEmpty ? null : title;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

Map<String, Object> _parseAnimeApiTsv(String filePath) {
  final lines = File(filePath).readAsLinesSync();
  if (lines.isEmpty) {
    throw const FormatException('AnimeApi database is empty.');
  }
  final headers = _splitTsvLine(lines.first);
  final titleIndex = headers.indexOf('title');
  if (titleIndex < 0 || !headers.contains('myanimelist')) {
    throw const FormatException('AnimeApi database has an unsupported schema.');
  }

  final records = <Map<String, String>>[];
  for (final line in lines.skip(1)) {
    if (line.isEmpty) continue;
    final fields = _splitTsvLine(line);
    if (fields.length != headers.length) continue;
    final row = <String, String>{};
    for (var index = 0; index < headers.length; index++) {
      final value = fields[index];
      if (value.isNotEmpty) row[headers[index]] = value;
    }
    if (row.isNotEmpty) records.add(row);
  }
  return {'records': records};
}

List<String> _splitTsvLine(String line) {
  final fields = <String>[];
  final field = StringBuffer();
  var quoted = false;

  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (character == '"') {
      if (quoted && index + 1 < line.length && line[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (character == '\t' && !quoted) {
      fields.add(field.toString());
      field.clear();
    } else {
      field.write(character);
    }
  }
  fields.add(field.toString());
  return fields;
}
