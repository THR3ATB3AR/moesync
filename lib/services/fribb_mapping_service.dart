import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'storage_service.dart';

class FribbMappingService {
  final StorageService _storage;
  List<FribbItem> _fribbItems = [];
  bool _isLoaded = false;

  FribbMappingService(this._storage);

  bool get isLoaded => _isLoaded;
  int get mappingsCount => _fribbItems.length;

  final Map<int, int> _anilistToMal = {};
  final Map<int, int> _kitsuToMal = {};
  final Map<int, int> _simklToMal = {};
  final Map<int, int> _malToAnilist = {};
  final Map<int, int> _malToKitsu = {};
  final Map<int, int> _malToSimkl = {};

  void _rebuildIndexes() {
    _anilistToMal.clear();
    _kitsuToMal.clear();
    _simklToMal.clear();
    _malToAnilist.clear();
    _malToKitsu.clear();
    _malToSimkl.clear();

    for (final f in _fribbItems) {
      if (f.malId <= 0) continue;
      if (f.anilistId > 0) {
        _anilistToMal[f.anilistId] = f.malId;
        _malToAnilist[f.malId] = f.anilistId;
      }
      if (f.kitsuId > 0) {
        _kitsuToMal[f.kitsuId] = f.malId;
        _malToKitsu[f.malId] = f.kitsuId;
      }
      if (f.simklId > 0) {
        _simklToMal[f.simklId] = f.malId;
        _malToSimkl[f.malId] = f.simklId;
      }
    }
  }

  Future<void> initialize() async {
    if (_isLoaded) return;

    final cached = _storage.getFribbCache();
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        _fribbItems = list
            .map((e) => FribbItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _rebuildIndexes();
        _isLoaded = true;
        return;
      } catch (_) {}
    }

    await refreshMapping();
  }

  Future<bool> refreshMapping() async {
    try {
      final resp = await http
          .get(
            Uri.parse(
              'https://raw.githubusercontent.com/Fribb/anime-lists/master/anime-list-full.json',
            ),
            headers: {'User-Agent': 'MoeSync/1.0.0'},
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        _fribbItems = list
            .map((e) => FribbItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _rebuildIndexes();
        await _storage.saveFribbCache(resp.body);
        _isLoaded = true;
        return true;
      }
    } catch (_) {}
    return false;
  }

  int findMalId(ServiceType service, int id) {
    if (service == ServiceType.mal || service == ServiceType.shikimori) {
      return id;
    }
    switch (service) {
      case ServiceType.anilist:
        return _anilistToMal[id] ?? 0;
      case ServiceType.kitsu:
        return _kitsuToMal[id] ?? 0;
      case ServiceType.simkl:
        return _simklToMal[id] ?? 0;
      default:
        return 0;
    }
  }

  Future<int> findMalIdWithFallback(ServiceType service, int id) async {
    return findMalId(service, id);
  }

  int findTargetId(int malId, ServiceType targetService) {
    if (targetService == ServiceType.mal ||
        targetService == ServiceType.shikimori) {
      return malId;
    }
    switch (targetService) {
      case ServiceType.anilist:
        return _malToAnilist[malId] ?? 0;
      case ServiceType.kitsu:
        return _malToKitsu[malId] ?? 0;
      case ServiceType.simkl:
        return _malToSimkl[malId] ?? 0;
      default:
        return 0;
    }
  }

  Future<int> findTargetIdWithFallback(
    int malId,
    ServiceType targetService,
  ) async {
    if (malId <= 0) return 0;
    if (targetService == ServiceType.mal ||
        targetService == ServiceType.shikimori) {
      return malId;
    }

    return findTargetId(malId, targetService);
  }
}
