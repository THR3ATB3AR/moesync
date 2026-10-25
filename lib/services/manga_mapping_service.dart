import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import 'mangabaka_service.dart';
import 'storage_service.dart';

class MangaMappingService {
  final StorageService _storage;
  final MangaBakaService _mangabaka;

  final Map<int, int> _anilistToMal = {};
  final Map<int, int> _kitsuToMal = {};
  final Map<int, int> _mangabakaToMal = {};
  final Map<int, int> _mangaupdatesToMal = {};

  final Map<int, int> _malToAnilist = {};
  final Map<int, int> _malToKitsu = {};
  final Map<int, int> _malToMangabaka = {};
  final Map<int, int> _malToMangaupdates = {};

  final Set<String> _failedLookups = {};

  bool _isLoaded = false;
  int _batchDepth = 0;
  bool _cacheDirty = false;
  bool get isLoaded => _isLoaded;
  int get mappingsCount => _malToMangabaka.length;

  MangaMappingService(this._storage, this._mangabaka) {
    _mangabaka.onSeriesFetched = recordFromMangaBakaSeries;
  }

  Future<void> initialize() async {
    if (_isLoaded) return;

    final cached = _storage.getMangaMappingCache();
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final malId = (item['mal'] as num?)?.toInt();
            final anilistId = (item['anilist'] as num?)?.toInt();
            final kitsuId = (item['kitsu'] as num?)?.toInt();
            final mangabakaId = (item['mangabaka'] as num?)?.toInt();
            final mangaupdatesId = (item['mangaupdates'] as num?)?.toInt();

            _recordInternal(
              malId: malId,
              anilistId: anilistId,
              kitsuId: kitsuId,
              mangabakaId: mangabakaId,
              mangaupdatesId: mangaupdatesId,
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to load cached manga mappings: $e');
      }
    }

    _isLoaded = true;
  }

  bool _recordInternal({
    int? malId,
    int? mangabakaId,
    int? mangaupdatesId,
    int? anilistId,
    int? kitsuId,
  }) {
    var changed = false;
    if (malId != null && malId > 0) {
      if (mangabakaId != null &&
          mangabakaId > 0 &&
          (_malToMangabaka[malId] != mangabakaId ||
              _mangabakaToMal[mangabakaId] != malId)) {
        _malToMangabaka[malId] = mangabakaId;
        _mangabakaToMal[mangabakaId] = malId;
        changed = true;
      }
      if (mangaupdatesId != null &&
          mangaupdatesId > 0 &&
          (_malToMangaupdates[malId] != mangaupdatesId ||
              _mangaupdatesToMal[mangaupdatesId] != malId)) {
        _malToMangaupdates[malId] = mangaupdatesId;
        _mangaupdatesToMal[mangaupdatesId] = malId;
        changed = true;
      }
      if (anilistId != null &&
          anilistId > 0 &&
          (_malToAnilist[malId] != anilistId ||
              _anilistToMal[anilistId] != malId)) {
        _malToAnilist[malId] = anilistId;
        _anilistToMal[anilistId] = malId;
        changed = true;
      }
      if (kitsuId != null &&
          kitsuId > 0 &&
          (_malToKitsu[malId] != kitsuId || _kitsuToMal[kitsuId] != malId)) {
        _malToKitsu[malId] = kitsuId;
        _kitsuToMal[kitsuId] = malId;
        changed = true;
      }
    }
    return changed;
  }

  void recordMapping({
    int? malId,
    int? mangabakaId,
    int? mangaupdatesId,
    int? anilistId,
    int? kitsuId,
  }) {
    final changed = _recordInternal(
      malId: malId,
      mangabakaId: mangabakaId,
      mangaupdatesId: mangaupdatesId,
      anilistId: anilistId,
      kitsuId: kitsuId,
    );
    if (!changed) return;
    _cacheDirty = true;
    if (_batchDepth == 0) {
      _persistCache();
    }
  }

  void beginBatch() {
    _batchDepth++;
  }

  Future<void> endBatch() async {
    if (_batchDepth == 0) {
      throw StateError('No manga mapping batch is active.');
    }
    _batchDepth--;
    if (_batchDepth == 0 && _cacheDirty) {
      await _persistCache(offloadEncoding: true);
    }
  }

  void recordFromMangaBakaSeries(Map<dynamic, dynamic> series) {
    int? asInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    int? extractId(dynamic obj) {
      if (obj == null) return null;
      if (obj is num) return obj.toInt();
      if (obj is String) return int.tryParse(obj);
      if (obj is Map) {
        return asInt(obj['id']);
      }
      return null;
    }

    int? extractMangaUpdatesId(dynamic obj) {
      if (obj == null) return null;
      if (obj is num) return obj.toInt();
      if (obj is String) {
        return int.tryParse(obj, radix: 36) ?? int.tryParse(obj);
      }
      if (obj is Map) {
        final id = obj['id'];
        if (id is num) return id.toInt();
        if (id is String) {
          return int.tryParse(id, radix: 36) ?? int.tryParse(id);
        }
      }
      return null;
    }

    final mangabakaId = asInt(series['id']);
    final source = series['source'] is Map ? series['source'] as Map : null;

    final malId = extractId(source?['my_anime_list']);
    final anilistId = extractId(source?['anilist']);
    final kitsuId = extractId(source?['kitsu']);
    final mangaupdatesId = extractMangaUpdatesId(source?['manga_updates']);

    if (malId != null && malId > 0) {
      recordMapping(
        malId: malId,
        mangabakaId: mangabakaId,
        mangaupdatesId: mangaupdatesId,
        anilistId: anilistId,
        kitsuId: kitsuId,
      );
    }
  }

  Future<void> _persistCache({bool offloadEncoding = false}) async {
    try {
      final allMalIds = {
        ..._malToMangabaka.keys,
        ..._malToMangaupdates.keys,
        ..._malToAnilist.keys,
        ..._malToKitsu.keys,
      };

      final export = allMalIds.map((malId) {
        return {
          'mal': malId,
          if (_malToMangabaka.containsKey(malId))
            'mangabaka': _malToMangabaka[malId],
          if (_malToMangaupdates.containsKey(malId))
            'mangaupdates': _malToMangaupdates[malId],
          if (_malToAnilist.containsKey(malId))
            'anilist': _malToAnilist[malId],
          if (_malToKitsu.containsKey(malId)) 'kitsu': _malToKitsu[malId],
        };
      }).toList();

      final encoded = offloadEncoding
          ? await compute(_encodeMappingCache, export)
          : jsonEncode(export);
      await _storage.saveMangaMappingCache(encoded);
      _cacheDirty = false;
    } catch (e) {
      debugPrint('Failed to persist manga mapping cache: $e');
    }
  }

  int findMalId(ServiceType service, int id) {
    if (service == ServiceType.mal || service == ServiceType.shikimori) {
      return id;
    }
    switch (service) {
      case ServiceType.mangabaka:
        return _mangabakaToMal[id] ?? 0;
      case ServiceType.mangaupdates:
        return _mangaupdatesToMal[id] ?? 0;
      case ServiceType.anilist:
        return _anilistToMal[id] ?? 0;
      case ServiceType.kitsu:
        return _kitsuToMal[id] ?? 0;
      default:
        return 0;
    }
  }

  Future<int> findMalIdWithLookup(ServiceType service, int id) async {
    if (service == ServiceType.mal || service == ServiceType.shikimori) {
      return id;
    }

    final cached = findMalId(service, id);
    if (cached > 0) return cached;

    String? sourceName;
    switch (service) {
      case ServiceType.mangaupdates:
        sourceName = 'manga-updates';
        break;
      case ServiceType.anilist:
        sourceName = 'anilist';
        break;
      case ServiceType.kitsu:
        sourceName = 'kitsu';
        break;
      default:
        break;
    }

    if (sourceName != null) {
      final lookupKey = '$sourceName/$id';
      if (_failedLookups.contains(lookupKey)) return 0;

      final series = await _mangabaka.fetchSourceSeries(sourceName, id);
      if (series != null) {
        recordFromMangaBakaSeries(series);
        final found = findMalId(service, id);
        if (found > 0) return found;
      }
      _failedLookups.add(lookupKey);
    }

    return 0;
  }

  int findTargetId(int malId, ServiceType targetService) {
    if (malId <= 0) return 0;
    if (targetService == ServiceType.mal ||
        targetService == ServiceType.shikimori) {
      return malId;
    }

    switch (targetService) {
      case ServiceType.mangabaka:
        return _malToMangabaka[malId] ?? 0;
      case ServiceType.mangaupdates:
        return _malToMangaupdates[malId] ?? 0;
      case ServiceType.anilist:
        return _malToAnilist[malId] ?? 0;
      case ServiceType.kitsu:
        return _malToKitsu[malId] ?? 0;
      default:
        return 0;
    }
  }

  Future<int> findTargetIdWithLookup(int malId, ServiceType targetService) async {
    if (malId <= 0) return 0;
    if (targetService == ServiceType.mal ||
        targetService == ServiceType.shikimori) {
      return malId;
    }
    if (targetService == ServiceType.simkl) {
      return 0;
    }

    final cached = findTargetId(malId, targetService);
    if (cached > 0) return cached;

    final lookupKey = 'mal/$malId';
    if (_failedLookups.contains(lookupKey)) return 0;

    final series = await _mangabaka.fetchSourceSeries('my-anime-list', malId);
    if (series != null) {
      recordFromMangaBakaSeries(series);
      final found = findTargetId(malId, targetService);
      if (found > 0) return found;
    }
    _failedLookups.add(lookupKey);

    return 0;
  }
}

String _encodeMappingCache(List<Map<String, Object?>> mappings) {
  return jsonEncode(mappings);
}
