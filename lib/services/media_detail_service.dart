import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/media_detail_data.dart';
import '../models/media_item.dart';
import 'anilist_rate_limiter.dart';
import 'anime_api_mapping_service.dart';
import 'manga_mapping_service.dart';
import 'mangaupdates_service.dart';
import 'storage_service.dart';

class MediaDetailService {
  final StorageService _storage;
  final AnimeApiMappingService _animeApi;
  final MangaMappingService _mangaMapping;

  MediaDetailService(this._storage, this._animeApi, this._mangaMapping);

  final Map<String, MediaDetailData> _cache = {};
  final Map<int, CharacterDetailData> _characterCache = {};
  final Map<int, StaffDetailData> _staffCache = {};

  Future<Map<ServiceType, MediaDetailData>> fetchAllServices({
    required UnifiedMediaItem item,
    required List<ServiceType> services,
    bool forceRefresh = false,
  }) async {
    final results = <ServiceType, MediaDetailData>{};

    int effectiveMalId = item.malId;
    if (effectiveMalId <= 0) {
      if (item.mediaType == MediaType.anime) {
        for (final entry in item.services.entries) {
          final found = _animeApi.findMalId(entry.key, entry.value.id);
          if (found > 0) {
            effectiveMalId = found;
            break;
          }
        }
      } else {
        for (final entry in item.services.entries) {
          final found = _mangaMapping.findMalId(entry.key, entry.value.id);
          if (found > 0) {
            effectiveMalId = found;
            break;
          }
        }
      }
    }

    final futures = services.map((s) async {
      final serviceItem = item.services[s];
      try {
        final data = await fetchDetails(
          service: s,
          serviceId: serviceItem?.id,
          malId: effectiveMalId,
          title: item.title,
          mediaType: item.mediaType,
          forceRefresh: forceRefresh,
        );
        if (data != null) {
          results[s] = data;
        }
      } catch (e) {
        if (e is TimeoutException) {
          debugPrint('${s.displayName} in fetchAllServices timed out');
        } else {
          debugPrint('Error loading $s in fetchAllServices: $e');
        }
      }
    });

    await Future.wait(futures);
    return results;
  }

  Future<MediaDetailData?> fetchDetails({
    required ServiceType service,
    required int? serviceId,
    required int malId,
    required String title,
    required MediaType mediaType,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${service.name}_${serviceId ?? malId}_${mediaType.name}';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      MediaDetailData? result;
      switch (service) {
        case ServiceType.anilist:
          result = await _fetchAniList(
            serviceId: serviceId,
            malId: malId,
            title: title,
            mediaType: mediaType,
          );
          break;
        case ServiceType.mal:
          result = await _fetchMal(
            serviceId: serviceId,
            malId: malId,
            title: title,
            mediaType: mediaType,
          );
          break;
        case ServiceType.kitsu:
          result = await _fetchKitsu(
            serviceId: serviceId,
            malId: malId,
            title: title,
            mediaType: mediaType,
          );
          break;
        case ServiceType.shikimori:
          result = await _fetchShikimori(
            serviceId: serviceId,
            malId: malId,
            title: title,
            mediaType: mediaType,
          );
          break;
        case ServiceType.simkl:
          result = await _fetchSimkl(
            simklId: serviceId,
            malId: malId,
            title: title,
            mediaType: mediaType,
          );
          break;
        case ServiceType.mangabaka:
          result = await _fetchMangaBaka(
            serviceId: serviceId,
            malId: malId,
            title: title,
          );
          break;
        case ServiceType.mangaupdates:
          result = await _fetchMangaUpdates(
            serviceId: serviceId,
            malId: malId,
            title: title,
          );
          break;
      }

      if (result != null) {
        _cache[cacheKey] = result;
        return result;
      }
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('${service.displayName} details timed out (fallback used)');
      } else {
        debugPrint('Error fetching details from ${service.displayName}: $e');
      }
    }

    return _buildFallback(
      service: service,
      serviceId: serviceId ?? malId,
      malId: malId,
      title: title,
      mediaType: mediaType,
    );
  }

  Future<MediaDetailData?> _fetchAniList({
    required int? serviceId,
    required int malId,
    required String title,
    required MediaType mediaType,
  }) async {
    const query = r'''
      query ($id: Int, $idMal: Int, $search: String, $type: MediaType) {
        Media(id: $id, idMal: $idMal, search: $search, type: $type) {
          id
          idMal
          title {
            userPreferred
            romaji
            english
            native
          }
          coverImage {
            extraLarge
            large
            medium
            color
          }
          bannerImage
          format
          status
          episodes
          chapters
          volumes
          duration
          season
          seasonYear
          startDate { year month day }
          endDate { year month day }
          averageScore
          meanScore
          popularity
          favourites
          trending
          source
          genres
          synonyms
          description(asHtml: false)
          nextAiringEpisode {
            episode
            airingAt
            timeUntilAiring
          }
          studios(isMain: true) {
            nodes {
              name
            }
          }
          staff(perPage: 12) {
            edges {
              role
              node {
                id
                name { full native }
                image { large medium }
              }
            }
          }
          characters(perPage: 25) {
            edges {
              role
              node {
                id
                name { full native alternative }
                image { large medium }
                description
                gender
                age
                bloodType
                dateOfBirth { year month day }
              }
              voiceActors(sort: [RELEVANCE, ID]) {
                id
                name { full native }
                languageV2
                image { large medium }
              }
            }
          }
          rankings {
            id
            rank
            type
            format
            year
            season
            allTime
            context
          }
          stats {
            statusDistribution {
              status
              amount
            }
            scoreDistribution {
              score
              amount
            }
          }
          relations {
            edges {
              relationType
              node {
                id
                idMal
                type
                format
                title { userPreferred }
                coverImage { large }
              }
            }
          }
          recommendations(perPage: 8) {
            nodes {
              mediaRecommendation {
                id
                idMal
                type
                format
                title { userPreferred }
                coverImage { large }
              }
            }
          }
        }
      }
    ''';

    final variables = <String, dynamic>{
      'type': mediaType == MediaType.anime ? 'ANIME' : 'MANGA',
    };
    if (serviceId != null && serviceId > 0) {
      variables['id'] = serviceId;
    } else if (malId > 0) {
      variables['idMal'] = malId;
    } else {
      variables['search'] = title;
    }

    final resp = await AnilistRateLimiter.post(
      url: Uri.parse('https://graphql.anilist.co'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'MoeSync/1.0.0',
      },
      body: {'query': query, 'variables': variables},
      timeout: const Duration(seconds: 10),
    );

    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final m = json['data']?['Media'] as Map<String, dynamic>?;
    if (m == null) return null;

    final id = (m['id'] as num).toInt();
    final idMal = (m['idMal'] as num?)?.toInt() ?? malId;

    final titleMap = (m['title'] as Map<String, dynamic>?) ?? {};
    final userPreferred = (titleMap['userPreferred'] as String?) ?? title;
    final romaji = titleMap['romaji'] as String?;
    final english = titleMap['english'] as String?;
    final native = titleMap['native'] as String?;

    final coverMap = (m['coverImage'] as Map<String, dynamic>?) ?? {};
    final poster =
        (coverMap['extraLarge'] as String?) ??
        (coverMap['large'] as String?) ??
        (coverMap['medium'] as String?) ??
        '';
    final banner = m['bannerImage'] as String?;

    final format = m['format'] as String?;
    final rawStatus = m['status'] as String?;
    final statusPl = _translateStatus(rawStatus);

    final episodes = (m['episodes'] as num?)?.toInt();
    final chapters = (m['chapters'] as num?)?.toInt();
    final volumes = (m['volumes'] as num?)?.toInt();
    final durationNum = (m['duration'] as num?)?.toInt();
    final duration = durationNum != null && durationNum > 0
        ? '$durationNum min'
        : null;

    final avgScore = (m['averageScore'] as num?)?.toDouble();
    final score = avgScore != null ? (avgScore / 10.0) : null;

    final genres = ((m['genres'] as List<dynamic>?) ?? []).cast<String>();
    final synonyms = ((m['synonyms'] as List<dynamic>?) ?? []).cast<String>();

    final seasonRaw = m['season'] as String?;
    final seasonYear =
        (m['seasonYear'] as num?)?.toInt() ??
        (m['startDate']?['year'] as num?)?.toInt();
    final seasonPl = seasonRaw != null
        ? '${_translateSeason(seasonRaw)} ${seasonYear ?? ''}'.trim()
        : (seasonYear != null ? '$seasonYear' : null);

    final startDate = _formatDate(m['startDate'] as Map<String, dynamic>?);
    final endDate = _formatDate(m['endDate'] as Map<String, dynamic>?);

    final source = _formatSource(m['source'] as String?);
    final desc = _cleanHtml(m['description'] as String?);

    final studioNodes = (m['studios']?['nodes'] as List<dynamic>?) ?? [];
    final studios = studioNodes
        .map((s) => s['name'] as String?)
        .whereType<String>()
        .toList();

    final charEdges = (m['characters']?['edges'] as List<dynamic>?) ?? [];
    final characters = charEdges.map((e) {
      final node = e['node'] as Map<String, dynamic>? ?? {};
      final charId = (node['id'] as num?)?.toInt() ?? 0;
      final name = node['name']?['full'] as String? ?? 'Postać';
      final nativeName = node['name']?['native'] as String?;
      final altNames = ((node['name']?['alternative'] as List<dynamic>?) ?? [])
          .cast<String>();
      final role = e['role'] == 'MAIN' ? 'Główna' : 'Poboczna';
      final img =
          (node['image']?['large'] as String?) ??
          (node['image']?['medium'] as String?);
      final desc = _cleanHtml(node['description'] as String?);
      final gender = node['gender'] as String?;
      final age = node['age']?.toString();
      final blood = node['bloodType'] as String?;
      final dob = _formatDate(node['dateOfBirth'] as Map<String, dynamic>?);

      final vaList = <MediaVoiceActorItem>[];
      final vaRaw = (e['voiceActors'] as List<dynamic>?) ?? [];
      for (final va in vaRaw) {
        if (va is Map<String, dynamic>) {
          final vaId = (va['id'] as num?)?.toInt() ?? 0;
          final vaName = va['name']?['full'] as String? ?? 'Aktor';
          final vaNative = va['name']?['native'] as String?;
          final vaLang = va['languageV2'] as String? ?? 'Japoński';
          final vaImg =
              (va['image']?['large'] as String?) ??
              (va['image']?['medium'] as String?);
          vaList.add(
            MediaVoiceActorItem(
              id: vaId,
              name: vaName,
              nativeName: vaNative,
              language: vaLang,
              imageUrl: vaImg,
            ),
          );
        }
      }

      return MediaCharacterItem(
        id: charId,
        name: name,
        nativeName: nativeName,
        alternativeNames: altNames,
        role: role,
        imageUrl: img,
        description: desc,
        gender: gender,
        age: age,
        bloodType: blood,
        dateOfBirth: dob,
        voiceActors: sortVoiceActors(vaList),
      );
    }).toList();

    final staffEdges = (m['staff']?['edges'] as List<dynamic>?) ?? [];
    final staff = staffEdges.map((e) {
      final node = e['node'] as Map<String, dynamic>? ?? {};
      final staffId = (node['id'] as num?)?.toInt() ?? 0;
      final name = node['name']?['full'] as String? ?? 'Twórca';
      final nativeName = node['name']?['native'] as String?;
      final role = e['role'] as String? ?? 'Personel';
      final img =
          (node['image']?['large'] as String?) ??
          (node['image']?['medium'] as String?);
      return MediaStaffItem(
        id: staffId,
        name: name,
        nativeName: nativeName,
        role: role,
        imageUrl: img,
      );
    }).toList();

    final rankingsList = (m['rankings'] as List<dynamic>?) ?? [];
    final rankings = rankingsList.map((r) {
      final rNum = (r['rank'] as num?)?.toInt() ?? 0;
      final type = r['type'] as String? ?? 'RATED';
      final ctx = r['context'] as String? ?? '';
      final isStar = type == 'RATED';
      return MediaRankingItem(rank: rNum, context: ctx, isStar: isStar);
    }).toList();

    final statusDist = <String, int>{};
    final distList =
        (m['stats']?['statusDistribution'] as List<dynamic>?) ?? [];
    for (final item in distList) {
      final s = item['status'] as String? ?? '';
      final amount = (item['amount'] as num?)?.toInt() ?? 0;
      statusDist[s.toLowerCase()] = amount;
    }

    final scoreDist = <int, int>{};
    final sList = (m['stats']?['scoreDistribution'] as List<dynamic>?) ?? [];
    for (final item in sList) {
      final sc = (item['score'] as num?)?.toInt() ?? 0;
      final amount = (item['amount'] as num?)?.toInt() ?? 0;
      scoreDist[sc] = amount;
    }

    final relEdges = (m['relations']?['edges'] as List<dynamic>?) ?? [];
    final relations = relEdges.map((e) {
      final node = e['node'] as Map<String, dynamic>? ?? {};
      final relType = e['relationType'] as String? ?? 'Powiązane';
      final rId = (node['id'] as num?)?.toInt() ?? 0;
      final rMalId = (node['idMal'] as num?)?.toInt();
      final rTitle = node['title']?['userPreferred'] as String? ?? 'Tytuł';
      final rCover = node['coverImage']?['large'] as String?;
      final rFormat = node['format'] as String?;
      final rMediaType = node['type'] == 'MANGA'
          ? MediaType.manga
          : MediaType.anime;
      return MediaRelationItem(
        id: rId,
        malId: rMalId,
        title: rTitle,
        relationType: _translateRelation(relType),
        format: rFormat,
        posterImage: rCover,
        mediaType: rMediaType,
        sourceService: ServiceType.anilist,
      );
    }).toList();

    final recNodes = (m['recommendations']?['nodes'] as List<dynamic>?) ?? [];
    final recommendations = recNodes.map((n) {
      final recMedia = n['mediaRecommendation'] as Map<String, dynamic>? ?? {};
      final recId = (recMedia['id'] as num?)?.toInt() ?? 0;
      final recMalId = (recMedia['idMal'] as num?)?.toInt();
      final recTitle =
          recMedia['title']?['userPreferred'] as String? ?? 'Polecane';
      final recCover = recMedia['coverImage']?['large'] as String?;
      final recFormat = recMedia['format'] as String?;
      final recMediaType = recMedia['type'] == 'MANGA'
          ? MediaType.manga
          : MediaType.anime;
      return MediaRecommendationItem(
        id: recId,
        malId: recMalId,
        title: recTitle,
        posterImage: recCover,
        format: recFormat,
        mediaType: recMediaType,
        sourceService: ServiceType.anilist,
      );
    }).toList();

    return MediaDetailData(
      sourceService: ServiceType.anilist,
      serviceId: id,
      malId: idMal,
      title: userPreferred,
      romajiTitle: romaji,
      englishTitle: english,
      nativeTitle: native,
      synonyms: synonyms,
      posterImage: poster,
      bannerImage: banner,
      format: format,
      year: seasonYear,
      status: statusPl,
      episodes: episodes,
      chapters: chapters,
      volumes: volumes,
      duration: duration,
      score: score,
      genres: genres,
      description: desc,
      rank: rankings.isNotEmpty ? rankings.first.rank : null,
      popularity: (m['popularity'] as num?)?.toInt(),
      favorites: (m['favourites'] as num?)?.toInt(),
      trending: (m['trending'] as num?)?.toInt(),
      startDate: startDate,
      endDate: endDate,
      season: seasonPl,
      broadcast: m['nextAiringEpisode'] != null
          ? 'Odc. ${m['nextAiringEpisode']['episode']} wkrótce'
          : null,
      source: source,
      studios: studios,
      characters: sortCharacters(characters),
      staff: sortStaff(staff),
      rankings: rankings,
      statusDistribution: statusDist,
      scoreDistribution: scoreDist,
      relations: relations,
      recommendations: recommendations,
    );
  }

  Future<MediaDetailData?> _fetchMal({
    required int? serviceId,
    required int malId,
    required String title,
    required MediaType mediaType,
  }) async {
    final typePath = mediaType == MediaType.anime ? 'anime' : 'manga';

    int resolvedMalId = malId > 0 ? malId : (serviceId ?? 0);
    if (resolvedMalId <= 0) {
      if (mediaType == MediaType.anime) {
        resolvedMalId = _animeApi.findMalId(ServiceType.mal, 0);
      } else {
        resolvedMalId = _mangaMapping.findMalId(ServiceType.mal, 0);
      }
    }

    final malCreds = _storage.getCredentials(ServiceType.mal);
    final clientId =
        (malCreds.clientId != null && malCreds.clientId!.isNotEmpty)
        ? malCreds.clientId!
        : StorageService.defaultMalClientId;

    final officialHeaders = <String, String>{'User-Agent': 'MoeSync/1.0.0'};
    if (malCreds.accessToken != null && malCreds.accessToken!.isNotEmpty) {
      officialHeaders['Authorization'] = 'Bearer ${malCreds.accessToken}';
    } else {
      officialHeaders['X-MAL-CLIENT-ID'] = clientId;
    }

    if (resolvedMalId <= 0 && title.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://api.myanimelist.net/v2/$typePath?q=${Uri.encodeComponent(title)}&limit=1&fields=id',
        );
        final searchResp = await http
            .get(searchUrl, headers: officialHeaders)
            .timeout(const Duration(seconds: 4));
        if (searchResp.statusCode == 200) {
          final sData = jsonDecode(searchResp.body) as Map<String, dynamic>;
          final list = (sData['data'] as List<dynamic>?) ?? [];
          if (list.isNotEmpty) {
            final firstNode = list.first['node'] as Map<String, dynamic>?;
            resolvedMalId = (firstNode?['id'] as num?)?.toInt() ?? 0;
          }
        }
      } catch (_) {}
    }

    if (resolvedMalId > 0) {
      try {
        final officialFields =
            'id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,nsfw,created_at,updated_at,media_type,status,genres,num_episodes,num_chapters,num_volumes,start_season,broadcast,source,average_episode_duration,rating,studios,authors,pictures,background,opening_themes,ending_themes,related_anime,related_manga,recommendations';
        final officialUrl = Uri.parse(
          'https://api.myanimelist.net/v2/$typePath/$resolvedMalId?fields=$officialFields',
        );

        final officialResp = await http
            .get(officialUrl, headers: officialHeaders)
            .timeout(const Duration(seconds: 8));

        if (officialResp.statusCode == 200) {
          final data = jsonDecode(officialResp.body) as Map<String, dynamic>;
          final parsed = _parseOfficialMalJson(
            data,
            resolvedMalId,
            title,
            mediaType,
          );
          if (parsed != null) return parsed;
        }
      } catch (e) {
        if (e is TimeoutException) {
          debugPrint('Official MAL request timed out');
        } else {
          debugPrint('Official MAL fetch error: $e');
        }
      }
    }

    return null;
  }

  MediaDetailData? _parseOfficialMalJson(
    Map<String, dynamic> data,
    int malId,
    String defaultTitle,
    MediaType mediaType,
  ) {
    final titleStr = (data['title'] as String?) ?? defaultTitle;
    final altTitles =
        (data['alternative_titles'] as Map<String, dynamic>?) ?? {};
    final english = altTitles['en'] as String?;
    final japanese = altTitles['ja'] as String?;
    final synonyms = ((altTitles['synonyms'] as List<dynamic>?) ?? [])
        .cast<String>();

    final mainPic = (data['main_picture'] as Map<String, dynamic>?) ?? {};
    final poster =
        (mainPic['large'] as String?) ?? (mainPic['medium'] as String?) ?? '';

    final format = (data['media_type'] as String?)?.toUpperCase();
    final statusPl = _translateStatus(data['status'] as String?);

    final episodes = (data['num_episodes'] as num?)?.toInt();
    final chapters = (data['num_chapters'] as num?)?.toInt();
    final volumes = (data['num_volumes'] as num?)?.toInt();

    final durationSec = (data['average_episode_duration'] as num?)?.toInt();
    final duration = durationSec != null && durationSec > 0
        ? '${(durationSec / 60).round()} min'
        : null;

    final score = (data['mean'] as num?)?.toDouble();
    final rank = (data['rank'] as num?)?.toInt();
    final popularity = (data['popularity'] as num?)?.toInt();
    final members = (data['num_list_users'] as num?)?.toInt();

    final genresList = (data['genres'] as List<dynamic>?) ?? [];
    final genres = genresList
        .map((g) => g['name'] as String?)
        .whereType<String>()
        .toList();

    final synopsis = data['synopsis'] as String?;
    final seasonData = data['start_season'] as Map<String, dynamic>?;
    final seasonName = seasonData?['season'] as String?;
    final seasonYear = (seasonData?['year'] as num?)?.toInt();
    final seasonPl = seasonName != null
        ? '${_translateSeason(seasonName)} ${seasonYear ?? ''}'.trim()
        : null;

    final startDate = data['start_date'] as String?;
    final endDate = data['end_date'] as String?;

    final broadcastData = data['broadcast'] as Map<String, dynamic>?;
    final broadcast = broadcastData?['day_of_the_week'] != null
        ? '${broadcastData!['day_of_the_week']} ${broadcastData['start_time'] ?? ""}'
              .trim()
        : null;

    final source = _formatSource(data['source'] as String?);

    final studiosList =
        (data['studios'] as List<dynamic>?) ??
        (data['authors'] as List<dynamic>?) ??
        [];
    final studios = studiosList
        .map((s) {
          if (s is Map) {
            final node = s['node'] as Map<String, dynamic>?;
            return (node?['name'] as String?) ?? (s['name'] as String?);
          }
          return null;
        })
        .whereType<String>()
        .toList();

    final openingThemes = <ThemeItem>[];
    final openingThemesRaw = (data['opening_themes'] as List<dynamic>?) ?? [];
    for (final t in openingThemesRaw) {
      if (t is Map) {
        final id = (t['id'] as num?)?.toInt() ?? 0;
        final animeId = (t['anime_id'] as num?)?.toInt() ?? 0;
        final text = t['text'] as String? ?? '';
        openingThemes.add(ThemeItem(id: id, animeId: animeId, text: text));
      }
    }

    final endingThemes = <ThemeItem>[];
    final endingThemesRaw = (data['ending_themes'] as List<dynamic>?) ?? [];
    for (final t in endingThemesRaw) {
      if (t is Map) {
        final id = (t['id'] as num?)?.toInt() ?? 0;
        final animeId = (t['anime_id'] as num?)?.toInt() ?? 0;
        final text = t['text'] as String? ?? '';
        endingThemes.add(ThemeItem(id: id, animeId: animeId, text: text));
      }
    }

    final relList = <MediaRelationItem>[];
    final relAnime = (data['related_anime'] as List<dynamic>?) ?? [];
    for (final r in relAnime) {
      final node = r['node'] as Map<String, dynamic>? ?? {};
      final rId = (node['id'] as num?)?.toInt() ?? 0;
      final rTitle = (node['title'] as String?) ?? 'Anime';
      final relType =
          (r['relation_type_formatted'] as String?) ??
          (r['relation_type'] as String?) ??
          'Powiązane';
      final pic = node['main_picture'] as Map<String, dynamic>?;
      final rImg = (pic?['large'] as String?) ?? (pic?['medium'] as String?);
      relList.add(
        MediaRelationItem(
          id: rId,
          malId: rId,
          title: rTitle,
          relationType: _translateRelation(relType),
          posterImage: rImg,
          mediaType: MediaType.anime,
          sourceService: ServiceType.mal,
        ),
      );
    }
    final relManga = (data['related_manga'] as List<dynamic>?) ?? [];
    for (final r in relManga) {
      final node = r['node'] as Map<String, dynamic>? ?? {};
      final rId = (node['id'] as num?)?.toInt() ?? 0;
      final rTitle = (node['title'] as String?) ?? 'Manga';
      final relType =
          (r['relation_type_formatted'] as String?) ??
          (r['relation_type'] as String?) ??
          'Powiązane';
      final pic = node['main_picture'] as Map<String, dynamic>?;
      final rImg = (pic?['large'] as String?) ?? (pic?['medium'] as String?);
      relList.add(
        MediaRelationItem(
          id: rId,
          malId: rId,
          title: rTitle,
          relationType: _translateRelation(relType),
          posterImage: rImg,
          mediaType: MediaType.manga,
          sourceService: ServiceType.mal,
        ),
      );
    }

    final recList = <MediaRecommendationItem>[];
    final recData = (data['recommendations'] as List<dynamic>?) ?? [];
    for (final rec in recData) {
      final node = rec['node'] as Map<String, dynamic>? ?? {};
      final recId = (node['id'] as num?)?.toInt() ?? 0;
      final recTitle = (node['title'] as String?) ?? 'Polecane';
      final pic = node['main_picture'] as Map<String, dynamic>?;
      final recImg = (pic?['large'] as String?) ?? (pic?['medium'] as String?);
      recList.add(
        MediaRecommendationItem(
          id: recId,
          malId: recId,
          title: recTitle,
          posterImage: recImg,
          mediaType: mediaType,
          sourceService: ServiceType.mal,
        ),
      );
    }

    final rankings = <MediaRankingItem>[];
    if (rank != null && rank > 0) {
      rankings.add(
        MediaRankingItem(
          rank: rank,
          context: 'Highest rated all time',
          isStar: true,
        ),
      );
    }
    if (popularity != null && popularity > 0) {
      rankings.add(
        MediaRankingItem(
          rank: popularity,
          context: 'Most popular all time',
          isStar: false,
        ),
      );
    }

    return MediaDetailData(
      sourceService: ServiceType.mal,
      serviceId: malId,
      malId: malId,
      title: titleStr,
      englishTitle: english,
      nativeTitle: japanese,
      synonyms: synonyms,
      posterImage: poster,
      format: format,
      status: statusPl,
      episodes: episodes,
      chapters: chapters,
      volumes: volumes,
      duration: duration,
      score: score,
      genres: genres,
      description: synopsis,
      rank: rank,
      popularity: members,
      startDate: startDate,
      endDate: endDate,
      season: seasonPl,
      broadcast: broadcast,
      source: source,
      studios: studios,
      rankings: rankings,
      openingThemes: openingThemes,
      endingThemes: endingThemes,
      relations: relList,
      recommendations: recList,
    );
  }

  Future<MediaDetailData?> _fetchKitsu({
    required int? serviceId,
    required int malId,
    required String title,
    required MediaType mediaType,
  }) async {
    int resolvedId = serviceId ?? 0;
    if (resolvedId <= 0) {
      if (mediaType == MediaType.anime) {
        resolvedId = _animeApi.findTargetId(malId, ServiceType.kitsu);
      } else {
        resolvedId = _mangaMapping.findTargetId(malId, ServiceType.kitsu);
      }
    }

    final typePath = mediaType == MediaType.anime ? 'anime' : 'manga';
    final url = resolvedId > 0
        ? Uri.parse(
            'https://kitsu.app/api/edge/$typePath/$resolvedId?include=genres',
          )
        : Uri.parse(
            'https://kitsu.app/api/edge/$typePath?filter[text]=${Uri.encodeComponent(title)}&include=genres&page[limit]=1',
          );

    final resp = await http
        .get(
          url,
          headers: {
            'Accept': 'application/vnd.api+json',
            'User-Agent': 'MoeSync/1.0.0',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = (json['data'] is List)
        ? (json['data'] as List).firstOrNull as Map<String, dynamic>?
        : json['data'] as Map<String, dynamic>?;

    if (data == null) return null;
    final id = int.tryParse(data['id']?.toString() ?? '') ?? (serviceId ?? 0);
    final attr = (data['attributes'] as Map<String, dynamic>?) ?? {};

    final titles = (attr['titles'] as Map<String, dynamic>?) ?? {};
    final canonicalTitle = (attr['canonicalTitle'] as String?) ?? title;
    final english = titles['en'] as String? ?? titles['en_jp'] as String?;
    final native = titles['ja_jp'] as String?;

    final posterMap = (attr['posterImage'] as Map<String, dynamic>?) ?? {};
    final poster =
        (posterMap['large'] as String?) ??
        (posterMap['original'] as String?) ??
        '';
    final coverMap = (attr['coverImage'] as Map<String, dynamic>?) ?? {};
    final banner =
        coverMap['large'] as String? ?? coverMap['original'] as String?;

    final subtype = attr['subtype'] as String?;
    final statusPl = _translateStatus(attr['status'] as String?);
    final episodeCount = (attr['episodeCount'] as num?)?.toInt();
    final chapterCount = (attr['chapterCount'] as num?)?.toInt();
    final volumeCount = (attr['volumeCount'] as num?)?.toInt();
    final episodeLength = (attr['episodeLength'] as num?)?.toInt();
    final duration = episodeLength != null && episodeLength > 0
        ? '$episodeLength min'
        : null;

    final avgRatingStr = attr['averageRating'] as String?;
    final score = avgRatingStr != null
        ? (double.tryParse(avgRatingStr) ?? 0) / 10.0
        : null;

    final popRank = (attr['popularityRank'] as num?)?.toInt();
    final ratingRank = (attr['ratingRank'] as num?)?.toInt();
    final userCount = (attr['userCount'] as num?)?.toInt();
    final favoritesCount = (attr['favoritesCount'] as num?)?.toInt();

    final startDate = attr['startDate'] as String?;
    final endDate = attr['endDate'] as String?;
    final synopsis = attr['synopsis'] as String?;

    final included = (json['included'] as List<dynamic>?) ?? [];
    final genres = included
        .where((inc) => inc['type'] == 'genres')
        .map((inc) => inc['attributes']?['name'] as String?)
        .whereType<String>()
        .toList();

    final rankings = <MediaRankingItem>[];
    if (ratingRank != null && ratingRank > 0) {
      rankings.add(
        MediaRankingItem(
          rank: ratingRank,
          context: 'Highest rated all time',
          isStar: true,
        ),
      );
    }
    if (popRank != null && popRank > 0) {
      rankings.add(
        MediaRankingItem(
          rank: popRank,
          context: 'Most popular all time',
          isStar: false,
        ),
      );
    }

    return MediaDetailData(
      sourceService: ServiceType.kitsu,
      serviceId: id,
      malId: malId,
      title: canonicalTitle,
      englishTitle: english,
      nativeTitle: native,
      posterImage: poster,
      bannerImage: banner,
      format: subtype?.toUpperCase(),
      status: statusPl,
      episodes: episodeCount,
      chapters: chapterCount,
      volumes: volumeCount,
      duration: duration,
      score: score,
      genres: genres,
      description: synopsis,
      rank: ratingRank,
      popularity: userCount,
      favorites: favoritesCount,
      startDate: startDate,
      endDate: endDate,
      rankings: rankings,
    );
  }

  Future<MediaDetailData?> _fetchShikimori({
    required int? serviceId,
    required int malId,
    required String title,
    required MediaType mediaType,
  }) async {
    int shikimoriId = (serviceId != null && serviceId > 0) ? serviceId : malId;
    final typePath = mediaType == MediaType.anime ? 'animes' : 'mangas';

    if (shikimoriId <= 0 && title.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://shikimori.io/api/$typePath?search=${Uri.encodeComponent(title)}&limit=1',
        );
        final searchResp = await http
            .get(searchUrl, headers: {'User-Agent': 'MoeSync/1.0.0'})
            .timeout(const Duration(seconds: 6));
        if (searchResp.statusCode == 200) {
          final list = jsonDecode(searchResp.body) as List<dynamic>;
          if (list.isNotEmpty) {
            shikimoriId = (list.first['id'] as num?)?.toInt() ?? 0;
          }
        }
      } catch (_) {}
    }

    if (shikimoriId <= 0) return null;

    final url = Uri.parse('https://shikimori.io/api/$typePath/$shikimoriId');

    final resp = await http
        .get(url, headers: {'User-Agent': 'MoeSync/1.0.0'})
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    final id = (data['id'] as num).toInt();
    final name = (data['name'] as String?) ?? title;
    final russian = data['russian'] as String?;
    final japaneseList = (data['japanese'] as List<dynamic>?) ?? [];
    final native = japaneseList.firstOrNull as String?;
    final synonyms = ((data['synonyms'] as List<dynamic>?) ?? [])
        .cast<String>();

    final imgMap = (data['image'] as Map<String, dynamic>?) ?? {};
    final original =
        imgMap['original'] as String? ?? imgMap['preview'] as String? ?? '';
    final poster = original.startsWith('http')
        ? original
        : 'https://shikimori.io$original';

    final kind = data['kind'] as String?;
    final statusPl = _translateStatus(data['status'] as String?);
    final episodes = (data['episodes'] as num?)?.toInt();
    final chapters = (data['chapters'] as num?)?.toInt();
    final volumes = (data['volumes'] as num?)?.toInt();
    final durationNum = (data['duration'] as num?)?.toInt();
    final duration = durationNum != null && durationNum > 0
        ? '$durationNum min'
        : null;

    double? score;
    final rawScore = data['score'];
    if (rawScore is num) {
      score = rawScore.toDouble();
    } else if (rawScore is String) {
      score = double.tryParse(rawScore);
    }

    final airedOn = data['aired_on'] as String?;
    final releasedOn = data['released_on'] as String?;
    final rawDesc = data['description'] as String?;
    final descHtml = data['description_html'] as String?;
    final desc = (rawDesc != null && rawDesc.trim().isNotEmpty)
        ? rawDesc.trim()
        : _cleanHtml(descHtml);

    final genresList = (data['genres'] as List<dynamic>?) ?? [];
    final genres = genresList
        .map((g) => (g['russian'] as String?) ?? (g['name'] as String?))
        .whereType<String>()
        .toList();

    final studiosList = (data['studios'] as List<dynamic>?) ?? [];
    final studios = studiosList
        .map((s) => s['name'] as String?)
        .whereType<String>()
        .toList();

    final statusDist = <String, int>{};
    final rateStats = (data['rates_statuses_stats'] as List<dynamic>?) ?? [];
    for (final st in rateStats) {
      final sName = st['name'] as String? ?? '';
      final val = (st['value'] as num?)?.toInt() ?? 0;
      statusDist[sName.toLowerCase()] = val;
    }

    final scoreDist = <int, int>{};
    final scoreStats = (data['rates_scores_stats'] as List<dynamic>?) ?? [];
    for (final st in scoreStats) {
      final sName = (st['name'] as num?)?.toInt() ?? 0;
      final val = (st['value'] as num?)?.toInt() ?? 0;
      scoreDist[sName * 10] = val;
    }

    return MediaDetailData(
      sourceService: ServiceType.shikimori,
      serviceId: id,
      malId: id,
      title: russian ?? name,
      romajiTitle: name,
      nativeTitle: native,
      synonyms: synonyms,
      posterImage: poster,
      format: kind?.toUpperCase(),
      status: statusPl,
      episodes: episodes,
      chapters: chapters,
      volumes: volumes,
      duration: duration,
      score: score,
      genres: genres,
      description: desc,
      startDate: airedOn,
      endDate: releasedOn,
      studios: studios,
      statusDistribution: statusDist,
      scoreDistribution: scoreDist,
    );
  }

  Future<MediaDetailData?> _fetchSimkl({
    required int? simklId,
    required int malId,
    required String title,
    required MediaType mediaType,
  }) async {
    final simklCreds = _storage.getCredentials(ServiceType.simkl);
    final clientId =
        (simklCreds.clientId != null && simklCreds.clientId!.isNotEmpty)
        ? simklCreds.clientId!
        : StorageService.defaultSimklClientId;

    int resolvedId = simklId ?? 0;
    if (resolvedId <= 0) {
      resolvedId = _animeApi.findTargetId(malId, ServiceType.simkl);
    }

    final url = resolvedId > 0
        ? Uri.parse(
            'https://api.simkl.com/anime/$resolvedId?client_id=$clientId&extended=full',
          )
        : (malId > 0
              ? Uri.parse(
                  'https://api.simkl.com/search/id?mal=$malId&client_id=$clientId',
                )
              : Uri.parse(
                  'https://api.simkl.com/search/anime?q=${Uri.encodeComponent(title)}&client_id=$clientId',
                ));

    final headers = <String, String>{
      'User-Agent': 'MoeSync/1.0.0',
      'simkl-api-key': clientId,
    };
    if (simklCreds.accessToken != null && simklCreds.accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${simklCreds.accessToken}';
    }

    final resp = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) return null;
    final dynamic decoded = jsonDecode(resp.body);
    final data = (decoded is List)
        ? decoded.firstOrNull as Map<String, dynamic>?
        : decoded as Map<String, dynamic>?;
    if (data == null) return null;

    final id = (data['ids']?['simkl'] as num?)?.toInt() ?? resolvedId;
    final titleStr = (data['title'] as String?) ?? title;
    final year = (data['year'] as num?)?.toInt();
    final posterPath = data['poster'] as String?;
    final poster = posterPath != null
        ? 'https://simkl.in/posters/${posterPath}_m.jpg'
        : '';

    final fanartPath = data['fanart'] as String?;
    final banner = fanartPath != null
        ? 'https://simkl.in/fanart/${fanartPath}_medium.jpg'
        : null;

    final ratings = data['ratings'] as Map<String, dynamic>? ?? {};
    final simklRating = ratings['simkl']?['rating'] as num?;
    final score = simklRating?.toDouble();

    final totalEp = (data['total_episodes'] as num?)?.toInt();
    final statusPl = _translateStatus(data['status'] as String?);
    final overview = data['overview'] as String?;

    final genresList = (data['genres'] as List<dynamic>?) ?? [];
    final genres = genresList.cast<String>();

    return MediaDetailData(
      sourceService: ServiceType.simkl,
      serviceId: id,
      malId: malId,
      title: titleStr,
      posterImage: poster,
      bannerImage: banner,
      format: (data['anime_type'] as String?)?.toUpperCase() ?? 'TV',
      year: year,
      status: statusPl,
      episodes: totalEp,
      score: score,
      genres: genres,
      description: overview,
    );
  }

  Future<MediaDetailData?> _fetchMangaBaka({
    required int? serviceId,
    required int malId,
    required String title,
  }) async {
    int resolvedId = serviceId ?? 0;
    if (resolvedId <= 0) {
      resolvedId = _mangaMapping.findTargetId(malId, ServiceType.mangabaka);
    }

    if (resolvedId <= 0 && title.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://api.mangabaka.org/v1/series/search?q=${Uri.encodeComponent(title)}',
        );
        final searchResp = await http
            .get(
              searchUrl,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'MoeSync/1.0.0',
              },
            )
            .timeout(const Duration(seconds: 6));

        if (searchResp.statusCode == 200) {
          final sJson = jsonDecode(searchResp.body) as Map<String, dynamic>;
          final list = (sJson['data'] as List<dynamic>?) ?? [];
          if (list.isNotEmpty) {
            final first = list.first as Map<String, dynamic>;
            resolvedId = (first['id'] as num?)?.toInt() ?? 0;
            if (resolvedId > 0 && malId > 0) {
              _mangaMapping.recordMapping(
                malId: malId,
                mangabakaId: resolvedId,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('MangaBaka search error: $e');
      }
    }

    if (resolvedId <= 0) return null;

    final url = Uri.parse(
      'https://api.mangabaka.org/v2/series/$resolvedId?schema=full',
    );
    var resp = await http
        .get(
          url,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'MoeSync/1.0.0',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) {
      final v1Url = Uri.parse(
        'https://api.mangabaka.org/v1/series/$resolvedId',
      );
      resp = await http
          .get(
            v1Url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'MoeSync/1.0.0',
            },
          )
          .timeout(const Duration(seconds: 6));
    }

    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final id = (data['id'] as num?)?.toInt() ?? resolvedId;
    final titleStr = (data['title'] as String?) ?? title;

    final altTitles = <String>[];
    if (data['titles'] is List) {
      for (final t in data['titles']) {
        if (t is Map && t['title'] is String) {
          altTitles.add(t['title'] as String);
        }
      }
    } else if (data['alternative_titles'] is List) {
      altTitles.addAll((data['alternative_titles'] as List).cast<String>());
    }

    String cover = '';
    final coverObj = data['cover'] ?? data['cover_image'];
    if (coverObj is String) {
      cover = coverObj;
    } else if (coverObj is Map) {
      for (final k in ['raw', 'x350', 'x250', 'x150']) {
        final val = coverObj[k];
        if (val is String && val.isNotEmpty) {
          cover = val;
          break;
        }
      }
    }

    final desc = data['description'] as String?;
    final scoreNum =
        (data['rating'] as num?)?.toDouble() ??
        (data['score'] as num?)?.toDouble();
    final statusPl = _translateStatus(data['status'] as String?);
    final chapters =
        (data['total_chapters'] as num?)?.toInt() ??
        (data['chapters'] as num?)?.toInt();
    final volumes =
        (data['total_volumes'] as num?)?.toInt() ??
        (data['volumes'] as num?)?.toInt();

    final genresList = (data['genres'] as List<dynamic>?) ?? [];
    final genres = genresList
        .map((g) {
          if (g is Map) return g['name'] as String?;
          if (g is String) return g;
          return null;
        })
        .whereType<String>()
        .toList();

    final authorsList = (data['authors'] as List<dynamic>?) ?? [];
    final authors = authorsList
        .map((a) {
          if (a is Map) return a['name'] as String?;
          if (a is String) return a;
          return null;
        })
        .whereType<String>()
        .toList();

    final relList = <MediaRelationItem>[];
    final rels =
        (data['relationships_v2'] as List<dynamic>?) ??
        (data['relationships'] as List<dynamic>?) ??
        [];
    for (final r in rels) {
      if (r is Map) {
        final rId =
            (r['target_series_id'] as num?)?.toInt() ??
            (r['series_id'] as num?)?.toInt() ??
            (r['id'] as num?)?.toInt() ??
            0;
        final rTitle =
            (r['title'] as String?) ?? (r['name'] as String?) ?? 'Manga';
        final rType = (r['relation_type'] as String?) ?? 'Powiązane';
        if (rId > 0) {
          relList.add(
            MediaRelationItem(
              id: rId,
              malId: 0,
              title: rTitle,
              relationType: _translateRelation(rType),
              format: 'MANGA',
              mediaType: MediaType.manga,
              sourceService: ServiceType.mangabaka,
            ),
          );
        }
      }
    }

    return MediaDetailData(
      sourceService: ServiceType.mangabaka,
      serviceId: id,
      malId: malId,
      title: titleStr,
      synonyms: altTitles,
      posterImage: cover,
      format: 'MANGA',
      status: statusPl,
      chapters: chapters,
      volumes: volumes,
      score: scoreNum,
      genres: genres,
      description: desc,
      studios: authors,
      relations: relList,
    );
  }

  Future<MediaDetailData?> _fetchMangaUpdates({
    required int? serviceId,
    required int malId,
    required String title,
  }) async {
    int resolvedId = serviceId ?? 0;
    if (resolvedId <= 0) {
      resolvedId = _mangaMapping.findTargetId(malId, ServiceType.mangaupdates);
      if (resolvedId <= 0 && malId > 0) {
        resolvedId = await _mangaMapping.findTargetIdWithLookup(
          malId,
          ServiceType.mangaupdates,
        );
      }
    }

    Map<String, dynamic>? searchFallbackRecord;

    if (resolvedId <= 0 && title.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://api.mangaupdates.com/v1/series/search',
        );
        var searchResp = await http
            .post(
              searchUrl,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'User-Agent': 'MoeSync/1.0.0',
              },
              body: jsonEncode({
                'search': title,
                'stype': 'title',
                'perpage': 5,
              }),
            )
            .timeout(const Duration(seconds: 6));

        var sJson = searchResp.statusCode == 200
            ? (jsonDecode(searchResp.body) as Map<String, dynamic>)
            : <String, dynamic>{};
        var results = (sJson['results'] as List<dynamic>?) ?? [];

        if (results.isEmpty && (title.contains(':') || title.contains('-'))) {
          final simplified = title.split(RegExp(r'[:\-]')).first.trim();
          if (simplified.isNotEmpty && simplified != title) {
            searchResp = await http
                .post(
                  searchUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'User-Agent': 'MoeSync/1.0.0',
                  },
                  body: jsonEncode({
                    'search': simplified,
                    'stype': 'title',
                    'perpage': 5,
                  }),
                )
                .timeout(const Duration(seconds: 6));
            if (searchResp.statusCode == 200) {
              sJson = jsonDecode(searchResp.body) as Map<String, dynamic>;
              results = (sJson['results'] as List<dynamic>?) ?? [];
            }
          }
        }

        if (results.isNotEmpty) {
          final firstRec = results.first['record'] as Map<String, dynamic>?;
          searchFallbackRecord = firstRec;
          resolvedId = _asInt(firstRec?['series_id']) ?? 0;
          if (resolvedId > 0 && malId > 0) {
            _mangaMapping.recordMapping(
              malId: malId,
              mangaupdatesId: resolvedId,
            );
          }
        }
      } catch (e) {
        debugPrint('MangaUpdates search error: $e');
      }
    }

    if (resolvedId <= 0 && searchFallbackRecord == null) return null;

    Map<String, dynamic>? data;
    if (resolvedId > 0) {
      try {
        final url = Uri.parse(
          'https://api.mangaupdates.com/v1/series/$resolvedId',
        );
        final resp = await http
            .get(
              url,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'MoeSync/1.0.0',
              },
            )
            .timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          data = jsonDecode(resp.body) as Map<String, dynamic>;
        }
      } catch (e) {
        if (e is TimeoutException) {
          debugPrint(
            'MangaUpdates series detail timed out, using search record',
          );
        } else {
          debugPrint('MangaUpdates fetch series detail error: $e');
        }
      }
    }

    data ??= searchFallbackRecord;
    if (data == null) return null;

    final id = _asInt(data['series_id']) ?? resolvedId;
    final titleStr = (data['title'] as String?) ?? title;
    final desc = _cleanHtml(data['description'] as String?);

    var poster = MangaUpdatesService.extractPoster(data['image']);
    if (poster.isEmpty) {
      poster = _storage.getMangaUpdatesPostersCache()[id] ?? '';
    } else {
      await _storage.saveSingleMangaUpdatesPoster(id, poster);
    }

    final scoreNum = _asDouble(data['bayesian_rating']);
    final year = _asInt(data['year']);
    final statusPl = _translateStatus(data['status'] as String?);

    final genresList = (data['genres'] as List<dynamic>?) ?? [];
    final genres = genresList
        .map((g) => g['genre'] as String?)
        .whereType<String>()
        .toList();

    final assocList = (data['associated'] as List<dynamic>?) ?? [];
    final synonyms = assocList
        .map((a) => a['title'] as String?)
        .whereType<String>()
        .toList();

    final authorsList = (data['authors'] as List<dynamic>?) ?? [];
    final authors = authorsList
        .map((a) => a['name'] as String?)
        .whereType<String>()
        .toList();

    final relList = <MediaRelationItem>[];
    final relSeries = (data['related_series'] as List<dynamic>?) ?? [];
    for (final r in relSeries) {
      if (r is Map) {
        final rId = _asInt(r['related_series_id']) ?? 0;
        final rName = (r['related_series_name'] as String?) ?? 'Manga';
        final rType = (r['relation_type'] as String?) ?? 'Powiązane';
        if (rId > 0) {
          relList.add(
            MediaRelationItem(
              id: rId,
              malId: 0,
              title: rName,
              relationType: _translateRelation(rType),
              format: 'MANGA',
              mediaType: MediaType.manga,
              sourceService: ServiceType.mangaupdates,
            ),
          );
        }
      }
    }

    return MediaDetailData(
      sourceService: ServiceType.mangaupdates,
      serviceId: id,
      malId: malId,
      title: titleStr,
      synonyms: synonyms,
      posterImage: poster,
      format: 'MANGA',
      year: year,
      status: statusPl,
      score: scoreNum,
      genres: genres,
      description: desc,
      studios: authors,
      relations: relList,
    );
  }

  MediaDetailData _buildFallback({
    required ServiceType service,
    required int serviceId,
    required int malId,
    required String title,
    required MediaType mediaType,
  }) {
    String fallbackPoster = '';
    if (service == ServiceType.mangaupdates) {
      fallbackPoster = _storage.getMangaUpdatesPostersCache()[serviceId] ?? '';
    }
    return MediaDetailData(
      sourceService: service,
      serviceId: serviceId,
      malId: malId,
      title: title,
      posterImage: fallbackPoster,
      format: mediaType == MediaType.anime ? 'TV' : 'MANGA',
      status: 'W trakcie',
    );
  }

  static String _translateStatus(String? raw) {
    if (raw == null) return 'Nieznany';
    final upper = raw.toUpperCase();
    if (upper.contains('FINISHED') || upper.contains('COMPLETED')) {
      return 'Ukończone';
    }
    if (upper.contains('RELEASING') ||
        upper.contains('CURRENT') ||
        upper.contains('ONGOING')) {
      return 'W trakcie';
    }
    if (upper.contains('NOT_YET_RELEASED') ||
        upper.contains('PLANNING') ||
        upper.contains('UPCOMING')) {
      return 'Planowane';
    }
    if (upper.contains('CANCELLED')) return 'Anulowane';
    if (upper.contains('HIATUS') || upper.contains('PAUSED')) {
      return 'Wstrzymane';
    }
    return raw;
  }

  static String _translateSeason(String season) {
    switch (season.toUpperCase()) {
      case 'WINTER':
        return 'Zima';
      case 'SPRING':
        return 'Wiosna';
      case 'SUMMER':
        return 'Lato';
      case 'FALL':
        return 'Jesień';
      default:
        return season;
    }
  }

  static String _translateRelation(String rel) {
    switch (rel.toUpperCase()) {
      case 'SEQUEL':
        return 'Kontynuacja';
      case 'PREQUEL':
        return 'Prequel';
      case 'SIDE_STORY':
        return 'Historia poboczna';
      case 'PARENT':
        return 'Główna seria';
      case 'ADAPTATION':
        return 'Adaptacja';
      case 'SPIN_OFF':
        return 'Spin-off';
      case 'ALTERNATIVE':
        return 'Wersja alternatywna';
      case 'SUMMARY':
        return 'Podsumowanie';
      default:
        return rel;
    }
  }

  static String? _formatDate(Map<String, dynamic>? dateMap) {
    if (dateMap == null) return null;
    final year = dateMap['year'] as int?;
    final month = dateMap['month'] as int?;
    final day = dateMap['day'] as int?;
    if (year == null) return null;

    const monthsPl = [
      'sty',
      'lut',
      'mar',
      'kwi',
      'maj',
      'cze',
      'lip',
      'sie',
      'wrz',
      'paź',
      'lis',
      'gru',
    ];

    if (day != null && month != null && month >= 1 && month <= 12) {
      return '$day ${monthsPl[month - 1]} $year';
    } else if (month != null && month >= 1 && month <= 12) {
      return '${monthsPl[month - 1]} $year';
    }
    return '$year';
  }

  static String? _formatSource(String? raw) {
    if (raw == null) return null;
    switch (raw.toUpperCase()) {
      case 'ORIGINAL':
        return 'Oryginalne';
      case 'MANGA':
        return 'Manga';
      case 'LIGHT_NOVEL':
        return 'Light Novel';
      case 'VISUAL_NOVEL':
        return 'Visual Novel';
      case 'VIDEO_GAME':
        return 'Gra wideo';
      case 'OTHER':
        return 'Inne';
      case 'NOVEL':
        return 'Powieść';
      case 'DOUJINSHI':
        return 'Doujinshi';
      case 'ANIME':
        return 'Anime';
      default:
        return raw;
    }
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _cleanHtml(String? text) {
    if (text == null) return null;
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\[/?[a-zA-Z0-9_-]+(?:=[^\]]+)?\]'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .trim();
  }

  Future<CharacterDetailData?> fetchCharacterDetails({
    required int id,
    int? malId,
    String? name,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && id > 0 && _characterCache.containsKey(id)) {
      return _characterCache[id];
    }

    if (id > 0) {
      try {
        final query = '''
          query (\$id: Int) {
            Character(id: \$id) {
              id
              name { full native alternative }
              image { large medium }
              description
              gender
              dateOfBirth { year month day }
              age
              bloodType
              media(sort: [FAVOURITES_DESC], perPage: 25) {
                edges {
                  characterRole
                  node {
                    id
                    idMal
                    type
                    title { userPreferred }
                    coverImage { large medium }
                  }
                  voiceActors(sort: [RELEVANCE, ID]) {
                    id
                    name { full native }
                    languageV2
                    image { large medium }
                  }
                }
              }
            }
          }
        ''';

        final resp = await AnilistRateLimiter.post(
          url: Uri.parse('https://graphql.anilist.co'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'MoeSync/1.0.0',
          },
          body: {
            'query': query,
            'variables': {'id': id},
          },
          timeout: const Duration(seconds: 10),
        );

        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final c = json['data']?['Character'] as Map<String, dynamic>?;
          if (c != null) {
            final parsed = _parseAniListCharacter(c);
            _characterCache[id] = parsed;
            return parsed;
          }
        }
      } catch (e) {
        debugPrint('AniList character fetch error: $e');
      }
    }

    return null;
  }

  Future<StaffDetailData?> fetchStaffDetails({
    required int id,
    int? malId,
    String? name,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && id > 0 && _staffCache.containsKey(id)) {
      return _staffCache[id];
    }

    if (id > 0) {
      try {
        const staffQuery = '''
          query (\$id: Int, \$page: Int) {
            Staff(id: \$id) {
              id
              name { full native alternative }
              image { large medium }
              description
              primaryOccupations
              gender
              dateOfBirth { year month day }
              dateOfDeath { year month day }
              age
              bloodType
              yearsActive
              homeTown
              siteUrl
              characters(sort: [FAVOURITES_DESC], perPage: 25, page: \$page) {
                pageInfo { hasNextPage }
                edges {
                  id
                  role
                  node {
                    id
                    name { full native }
                    image { large medium }
                  }
                  media {
                    id
                    idMal
                    type
                    title { userPreferred }
                    coverImage { large medium }
                  }
                }
              }
              staffMedia(sort: [FAVOURITES_DESC], perPage: 25) {
                edges {
                  staffRole
                  node {
                    id
                    idMal
                    type
                    title { userPreferred }
                    coverImage { large medium }
                  }
                }
              }
            }
          }
        ''';

        Map<String, dynamic>? staffData;
        final allCharEdges = <dynamic>[];
        int page = 1;
        bool hasNextPage = true;

        while (hasNextPage) {
          final resp = await AnilistRateLimiter.post(
            url: Uri.parse('https://graphql.anilist.co'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'MoeSync/1.0.0',
            },
            body: {
              'query': staffQuery,
              'variables': {'id': id, 'page': page},
            },
            timeout: const Duration(seconds: 10),
          );

          if (resp.statusCode != 200) break;
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final s = json['data']?['Staff'] as Map<String, dynamic>?;
          if (s == null) break;

          staffData ??= s;
          final edges = (s['characters']?['edges'] as List<dynamic>?) ?? [];
          allCharEdges.addAll(edges);
          hasNextPage = s['characters']?['pageInfo']?['hasNextPage'] == true;
          page++;
        }

        if (staffData != null) {
          final mutableStaff = Map<String, dynamic>.from(staffData);
          mutableStaff['characters'] = {'edges': allCharEdges};
          final parsed = _parseAniListStaff(mutableStaff);
          _staffCache[id] = parsed;
          return parsed;
        }
      } catch (e) {
        debugPrint('AniList staff fetch error: \$e');
      }
    }

    return null;
  }

  CharacterDetailData _parseAniListCharacter(Map<String, dynamic> c) {
    final id = (c['id'] as num?)?.toInt() ?? 0;
    final name = c['name']?['full'] as String? ?? 'Postać';
    final native = c['name']?['native'] as String?;
    final altNames = ((c['name']?['alternative'] as List<dynamic>?) ?? [])
        .cast<String>();
    final img =
        (c['image']?['large'] as String?) ?? (c['image']?['medium'] as String?);
    final desc = _cleanHtml(c['description'] as String?);
    final gender = c['gender'] as String?;
    final age = c['age']?.toString();
    final blood = c['bloodType'] as String?;
    final dob = _formatDate(c['dateOfBirth'] as Map<String, dynamic>?);

    final appearances = <CharacterMediaAppearance>[];
    final voiceActorsMap = <int, MediaVoiceActorItem>{};

    final mediaEdges = (c['media']?['edges'] as List<dynamic>?) ?? [];
    for (final edge in mediaEdges) {
      final node = edge['node'] as Map<String, dynamic>? ?? {};
      final mId = (node['id'] as num?)?.toInt() ?? 0;
      final mMalId = (node['idMal'] as num?)?.toInt();
      final mType = node['type'] == 'MANGA' ? MediaType.manga : MediaType.anime;
      final mTitle = (node['title']?['userPreferred'] as String?) ?? '';
      final mCover =
          (node['coverImage']?['large'] as String?) ??
          (node['coverImage']?['medium'] as String?);
      final rawRole = edge['characterRole'] as String? ?? 'MAIN';
      final role = rawRole == 'MAIN' ? 'Główna' : 'Poboczna';

      appearances.add(
        CharacterMediaAppearance(
          mediaId: mId,
          mediaMalId: mMalId,
          mediaTitle: mTitle,
          mediaType: mType,
          mediaPosterImage: mCover,
          role: role,
        ),
      );

      final vaList = (edge['voiceActors'] as List<dynamic>?) ?? [];
      for (final va in vaList) {
        if (va is Map<String, dynamic>) {
          final vaId = (va['id'] as num?)?.toInt() ?? 0;
          if (vaId > 0 && !voiceActorsMap.containsKey(vaId)) {
            voiceActorsMap[vaId] = MediaVoiceActorItem(
              id: vaId,
              name: (va['name']?['full'] as String?) ?? 'Aktor',
              nativeName: va['name']?['native'] as String?,
              language: (va['languageV2'] as String?) ?? 'Japoński',
              imageUrl:
                  (va['image']?['large'] as String?) ??
                  (va['image']?['medium'] as String?),
            );
          }
        }
      }
    }

    return CharacterDetailData(
      id: id,
      name: name,
      nativeName: native,
      alternativeNames: altNames,
      imageUrl: img,
      description: desc,
      gender: gender,
      age: age,
      dateOfBirth: dob,
      bloodType: blood,
      mediaAppearances: appearances,
      voiceActors: sortVoiceActors(voiceActorsMap.values.toList()),
    );
  }

  StaffDetailData _parseAniListStaff(Map<String, dynamic> s) {
    final id = (s['id'] as num?)?.toInt() ?? 0;
    final name = (s['name']?['full'] as String?) ?? 'Actor';
    final native = s['name']?['native'] as String?;
    final altNames = ((s['name']?['alternative'] as List<dynamic>?) ?? [])
        .cast<String>();
    final img =
        (s['image']?['large'] as String?) ?? (s['image']?['medium'] as String?);
    final desc = _cleanHtml(s['description'] as String?);
    final occupations = ((s['primaryOccupations'] as List<dynamic>?) ?? [])
        .cast<String>();
    final gender = s['gender'] as String?;
    final age = (s['age'] as num?)?.toInt();
    final blood = s['bloodType'] as String?;
    final homeTown = s['homeTown'] as String?;
    final dob = _formatDate(s['dateOfBirth'] as Map<String, dynamic>?);
    final dod = _formatDate(s['dateOfDeath'] as Map<String, dynamic>?);

    String? yearsActive;
    final yaRaw = s['yearsActive'] as List<dynamic>?;
    if (yaRaw != null && yaRaw.isNotEmpty) {
      if (yaRaw.length == 1) {
        yearsActive = '${yaRaw.first} - Obecnie';
      } else {
        yearsActive = '${yaRaw.first} - ${yaRaw.last ?? "Obecnie"}';
      }
    }

    final websites = <String>[];
    final siteUrl = s['siteUrl'] as String?;
    if (siteUrl != null && siteUrl.isNotEmpty) websites.add(siteUrl);

    final charRoles = <VoiceActorCharacterRole>[];
    final charEdges = (s['characters']?['edges'] as List<dynamic>?) ?? [];
    for (final ce in charEdges) {
      final cNode = ce['node'] as Map<String, dynamic>? ?? {};
      final cId = (cNode['id'] as num?)?.toInt() ?? 0;
      final cName = (cNode['name']?['full'] as String?) ?? '';
      final cImg =
          (cNode['image']?['large'] as String?) ??
          (cNode['image']?['medium'] as String?);

      dynamic mRaw = ce['media'];
      Map<String, dynamic>? mNode;
      if (mRaw is List && mRaw.isNotEmpty) {
        mNode = mRaw.first as Map<String, dynamic>?;
      } else if (mRaw is Map<String, dynamic>) {
        mNode = mRaw;
      }

      final mId = (mNode?['id'] as num?)?.toInt() ?? 0;
      final mMalId = (mNode?['idMal'] as num?)?.toInt();
      final mTitle = (mNode?['title']?['userPreferred'] as String?) ?? '';
      final mType = mNode?['type'] == 'MANGA'
          ? MediaType.manga
          : MediaType.anime;
      final mCover =
          (mNode?['coverImage']?['large'] as String?) ??
          (mNode?['coverImage']?['medium'] as String?);
      final role = ce['role'] as String?;

      charRoles.add(
        VoiceActorCharacterRole(
          characterId: cId,
          characterName: cName,
          characterImageUrl: cImg,
          mediaId: mId,
          mediaMalId: mMalId,
          mediaTitle: mTitle,
          mediaType: mType,
          mediaPosterImage: mCover,
          role: role,
        ),
      );
    }

    final mediaRoles = <VoiceActorMediaRole>[];
    final staffEdges = (s['staffMedia']?['edges'] as List<dynamic>?) ?? [];
    for (final se in staffEdges) {
      final mNode = se['node'] as Map<String, dynamic>? ?? {};
      final mId = (mNode['id'] as num?)?.toInt() ?? 0;
      final mMalId = (mNode['idMal'] as num?)?.toInt();
      final mTitle = (mNode['title']?['userPreferred'] as String?) ?? '';
      final mType = mNode['type'] == 'MANGA'
          ? MediaType.manga
          : MediaType.anime;
      final mCover =
          (mNode['coverImage']?['large'] as String?) ??
          (mNode['coverImage']?['medium'] as String?);
      final role = (se['staffRole'] as String?) ?? 'Staff';

      mediaRoles.add(
        VoiceActorMediaRole(
          mediaId: mId,
          mediaMalId: mMalId,
          mediaTitle: mTitle,
          mediaType: mType,
          mediaPosterImage: mCover,
          role: role,
        ),
      );
    }

    return StaffDetailData(
      id: id,
      name: name,
      nativeName: native,
      alternativeNames: altNames,
      imageUrl: img,
      description: desc,
      birthday: dob,
      deathday: dod,
      age: age,
      gender: gender,
      bloodType: blood,
      yearsActive: yearsActive,
      homeTown: homeTown,
      occupations: occupations,
      websiteUrls: websites,
      characterRoles: stableSort(charRoles, (a, b) {
        final prioA = getCharacterRolePriority(a.role ?? '');
        final prioB = getCharacterRolePriority(b.role ?? '');
        return prioA.compareTo(prioB);
      }),
      mediaRoles: stableSort(mediaRoles, (a, b) {
        final prioA = getStaffRolePriority(a.role);
        final prioB = getStaffRolePriority(b.role);
        return prioA.compareTo(prioB);
      }),
    );
  }
}
