import 'dart:async';

import 'package:flutter/material.dart';

import '../models/media_item.dart';
import 'anilist_service.dart';
import 'fribb_mapping_service.dart';
import 'kitsu_service.dart';
import 'mal_service.dart';
import 'manga_mapping_service.dart';
import 'mangabaka_service.dart';
import 'mangaupdates_service.dart';
import 'shikimori_service.dart';
import 'simkl_service.dart';

class SyncEngine {
  final MalService mal;
  final AnilistService anilist;
  final KitsuService kitsu;
  final ShikimoriService shikimori;
  final SimklService simkl;
  final FribbMappingService fribb;
  final MangaBakaService? mangabaka;
  final MangaUpdatesService? mangaupdates;
  final MangaMappingService? mangaMapping;

  SyncEngine({
    required this.mal,
    required this.anilist,
    required this.kitsu,
    required this.shikimori,
    required this.simkl,
    required this.fribb,
    this.mangabaka,
    this.mangaupdates,
    this.mangaMapping,
  });

  bool isServiceConnected(ServiceType service) {
    switch (service) {
      case ServiceType.mal:
        return mal.isAuthenticated;
      case ServiceType.anilist:
        return anilist.isAuthenticated;
      case ServiceType.kitsu:
        return kitsu.isAuthenticated;
      case ServiceType.shikimori:
        return shikimori.isAuthenticated;
      case ServiceType.simkl:
        return simkl.isAuthenticated;
      case ServiceType.mangabaka:
        return mangabaka?.isAuthenticated ?? false;
      case ServiceType.mangaupdates:
        return mangaupdates?.isAuthenticated ?? false;
    }
  }

  final Map<ServiceType, String> lastFetchErrors = {};
  Map<ServiceType, String> get serviceErrors =>
      Map.unmodifiable(lastFetchErrors);

  Future<Map<ServiceType, List<MediaItem>>> fetchAllServices(
    MediaType type, {
    Map<ServiceType, String>? errorsOut,
    bool forceRefresh = false,
    FutureOr<void> Function(ServiceType service, List<MediaItem> items)?
    onServiceLoaded,
  }) async {
    lastFetchErrors.clear();
    final results = <ServiceType, List<MediaItem>>{};
    final errors = <ServiceType, String>{};
    final futures = <Future<void>>[];

    void addFetch(
      ServiceType service,
      Future<List<MediaItem>> Function() fetch,
    ) {
      futures.add(() async {
        late final List<MediaItem> items;
        try {
          items = await fetch();
        } catch (e) {
          debugPrint('Failed to fetch ${service.displayName}: $e');
          errors[service] = e.toString().replaceFirst('Exception: ', '');
          return;
        }

        results[service] = items;
        await onServiceLoaded?.call(service, items);
      }());
    }

    if (mal.isAuthenticated) {
      addFetch(ServiceType.mal, () => mal.fetchList(type));
    }
    if (anilist.isAuthenticated) {
      addFetch(
        ServiceType.anilist,
        () => anilist.fetchList(type, forceRefresh: forceRefresh),
      );
    }
    if (kitsu.isAuthenticated) {
      addFetch(ServiceType.kitsu, () => kitsu.fetchList(type));
    }
    if (shikimori.isAuthenticated) {
      addFetch(ServiceType.shikimori, () => shikimori.fetchList(type));
    }
    if (simkl.isAuthenticated && type == MediaType.anime) {
      addFetch(ServiceType.simkl, () => simkl.fetchList(type));
    }
    if (type == MediaType.manga) {
      if (mangabaka != null && mangabaka!.isAuthenticated) {
        addFetch(ServiceType.mangabaka, () => mangabaka!.fetchList(type));
      }
      if (mangaupdates != null && mangaupdates!.isAuthenticated) {
        addFetch(ServiceType.mangaupdates, () => mangaupdates!.fetchList(type));
      }
    }

    await Future.wait(futures);

    lastFetchErrors.addAll(errors);
    if (errorsOut != null) {
      errorsOut.addAll(errors);
    }

    return results;
  }

  Future<List<UnifiedMediaItem>> buildUnifiedList(
    MediaType type, {
    bool forceRefresh = false,
    Map<ServiceType, String>? errorsOut,
    FutureOr<void> Function(List<UnifiedMediaItem> items)? onItemsLoaded,
  }) async {
    final mappingFutures = <Future<void>>[fribb.initialize()];
    if (mangaMapping != null) {
      mappingFutures.add(mangaMapping!.initialize());
    }
    final mappingsReady = Future.wait(mappingFutures);
    final allServiceItems = <ServiceType, List<MediaItem>>{};
    var pendingUpdates = Future<void>.value();
    final results = await Future.wait([
      mappingsReady,
      fetchAllServices(
        type,
        errorsOut: errorsOut,
        forceRefresh: forceRefresh,
        onServiceLoaded: (service, items) {
          if (onItemsLoaded == null) return Future<void>.value();

          pendingUpdates = pendingUpdates.then((_) async {
            allServiceItems[service] = items;
            await mappingsReady;
            await onItemsLoaded(
              _buildUnifiedListFromServices(type, allServiceItems),
            );
          });
          return pendingUpdates;
        },
      ),
    ]);
    allServiceItems.addAll(results[1] as Map<ServiceType, List<MediaItem>>);

    if (type == MediaType.manga) {
      await _resolveMangaMappings(allServiceItems);
    }

    return _buildUnifiedListFromServices(type, allServiceItems);
  }

  List<UnifiedMediaItem> _buildUnifiedListFromServices(
    MediaType type,
    Map<ServiceType, List<MediaItem>> allServiceItems,
  ) {
    final unifiedMap = <int, UnifiedMediaItem>{};

    for (final entry in allServiceItems.entries) {
      final service = entry.key;
      final items = entry.value;

      for (final item in items) {
        int malId;
        if (type == MediaType.manga) {
          if (service == ServiceType.mal || service == ServiceType.shikimori) {
            malId = item.id;
          } else if (item.malId != null && item.malId! > 0) {
            malId = item.malId!;
          } else {
            malId = mangaMapping?.findMalId(service, item.id) ?? 0;
          }
        } else {
          malId =
              (service == ServiceType.mal || service == ServiceType.shikimori)
              ? item.id
              : (item.malId != null && item.malId! > 0)
              ? item.malId!
              : fribb.findMalId(service, item.id);
        }
        final effectiveKey = malId != 0
            ? malId
            : (item.id + service.index * 1000000);

        if (!unifiedMap.containsKey(effectiveKey)) {
          unifiedMap[effectiveKey] = UnifiedMediaItem(
            malId: effectiveKey,
            title: item.title,
            posterImage: item.posterImage,
            mediaType: type,
            services: {},
          );
        }

        final u = unifiedMap[effectiveKey]!;
        u.services[service] = item;
      }
    }

    return unifiedMap.values.toList();
  }

  static String _normalizeTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> _resolveMangaMappings(
    Map<ServiceType, List<MediaItem>> allServiceItems,
  ) async {
    if (mangaMapping == null) return;

    for (final entry in allServiceItems.entries) {
      final service = entry.key;
      for (final item in entry.value) {
        if (service == ServiceType.mal || service == ServiceType.shikimori) {
          mangaMapping!.recordMapping(malId: item.id);
        } else if (item.malId != null && item.malId! > 0) {
          mangaMapping!.recordMapping(
            malId: item.malId!,
            mangabakaId: service == ServiceType.mangabaka ? item.id : null,
            mangaupdatesId: service == ServiceType.mangaupdates
                ? item.id
                : null,
            anilistId: service == ServiceType.anilist ? item.id : null,
            kitsuId: service == ServiceType.kitsu ? item.id : null,
          );
        }
      }
    }

    final unmappedItems = <MediaItem>[];
    for (final entry in allServiceItems.entries) {
      final service = entry.key;
      if (service == ServiceType.mangaupdates ||
          service == ServiceType.kitsu ||
          service == ServiceType.mangabaka) {
        for (final item in entry.value) {
          if ((item.malId == null || item.malId == 0) &&
              mangaMapping!.findMalId(service, item.id) == 0) {
            unmappedItems.add(item);
          }
        }
      }
    }

    if (unmappedItems.isEmpty) return;

    final knownTitleToMal = <String, int>{};
    for (final entry in allServiceItems.entries) {
      for (final item in entry.value) {
        final mId =
            (entry.key == ServiceType.mal || entry.key == ServiceType.shikimori)
            ? item.id
            : (item.malId ?? mangaMapping!.findMalId(entry.key, item.id));
        if (mId > 0) {
          final norm = _normalizeTitle(item.title);
          if (norm.isNotEmpty) knownTitleToMal[norm] = mId;
        }
      }
    }

    final stillUnmapped = <MediaItem>[];
    for (final item in unmappedItems) {
      final norm = _normalizeTitle(item.title);
      final matchedMal = knownTitleToMal[norm];
      if (matchedMal != null && matchedMal > 0) {
        mangaMapping!.recordMapping(
          malId: matchedMal,
          mangaupdatesId: item.service == ServiceType.mangaupdates
              ? item.id
              : null,
          kitsuId: item.service == ServiceType.kitsu ? item.id : null,
          mangabakaId: item.service == ServiceType.mangabaka ? item.id : null,
        );
      } else {
        stillUnmapped.add(item);
      }
    }

    const batchSize = 3;
    for (var i = 0; i < stillUnmapped.length; i += batchSize) {
      final batch = stillUnmapped.skip(i).take(batchSize);
      await Future.wait(
        batch.map((item) async {
          try {
            final found = await mangaMapping!.findMalIdWithLookup(
              item.service,
              item.id,
            );
            if (found == 0 && item.service == ServiceType.kitsu) {
              final kMal = await kitsu.findMalIdByKitsuId(
                item.id,
                MediaType.manga,
              );
              if (kMal != null && kMal > 0) {
                mangaMapping!.recordMapping(malId: kMal, kitsuId: item.id);
              }
            }
          } catch (_) {}
        }),
      );
    }
  }

  Future<int> resolveTargetId({
    required int malId,
    required ServiceType targetService,
    required MediaType mediaType,
  }) async {
    if (malId <= 0) return 0;

    if (targetService == ServiceType.mal ||
        targetService == ServiceType.shikimori) {
      return malId;
    }

    if (mediaType == MediaType.anime) {
      final targetId = fribb.findTargetId(malId, targetService);
      if (targetId > 0) return targetId;

      if (targetService == ServiceType.simkl) {
        return 0;
      }

      if (targetService == ServiceType.anilist) {
        final aId = await anilist.findMediaIdByMalId(malId, MediaType.anime);
        if (aId != null && aId > 0) return aId;
      } else if (targetService == ServiceType.kitsu) {
        final kId = await kitsu.findMediaIdByMalId(malId, MediaType.anime);
        if (kId != null && kId > 0) return kId;
      }
    } else if (mediaType == MediaType.manga) {
      if (targetService == ServiceType.simkl) {
        return 0;
      }

      if (mangaMapping != null) {
        final mId = await mangaMapping!.findTargetIdWithLookup(
          malId,
          targetService,
        );
        if (mId > 0) return mId;
      }

      if (targetService == ServiceType.anilist) {
        final aId = await anilist.findMediaIdByMalId(malId, MediaType.manga);
        if (aId != null && aId > 0) return aId;
      } else if (targetService == ServiceType.kitsu) {
        final kId = await kitsu.findMediaIdByMalId(malId, MediaType.manga);
        if (kId != null && kId > 0) return kId;
      }
    }

    return 0;
  }

  Future<List<SyncAction>> computeSyncActions({
    required ServiceType primaryService,
    required MediaType mediaType,
    bool onlyExisting = false,
    bool forceRefresh = false,
    Map<ServiceType, String>? errorsOut,
  }) async {
    final fetchErrors = <ServiceType, String>{};
    final mappingFutures = <Future<void>>[fribb.initialize()];
    if (mangaMapping != null) {
      mappingFutures.add(mangaMapping!.initialize());
    }
    final futures = await Future.wait([
      Future.wait(mappingFutures),
      fetchAllServices(
        mediaType,
        errorsOut: fetchErrors,
        forceRefresh: forceRefresh,
      ),
    ]);
    final allServiceItems = futures[1] as Map<ServiceType, List<MediaItem>>;
    errorsOut?.addAll(fetchErrors);

    if (fetchErrors.containsKey(primaryService)) {
      debugPrint(
        'Primary service $primaryService failed to fetch. Aborting diff computation.',
      );
      return [];
    }

    if (mediaType == MediaType.manga) {
      await _resolveMangaMappings(allServiceItems);
    }

    final primaryItems = allServiceItems[primaryService] ?? [];

    if (primaryItems.isEmpty) return [];

    final actions = <SyncAction>[];

    final targetByMalId = <ServiceType, Map<int, MediaItem>>{};
    final targetByServiceId = <ServiceType, Map<int, MediaItem>>{};
    final targetByTitle = <ServiceType, Map<String, MediaItem>>{};

    for (final service in ServiceType.values) {
      if (service == primaryService) continue;
      targetByMalId[service] = {};
      targetByServiceId[service] = {};
      targetByTitle[service] = {};

      final items = allServiceItems[service] ?? [];
      for (final item in items) {
        targetByServiceId[service]![item.id] = item;
        final cleanTitle = _normalizeTitle(item.title);
        if (cleanTitle.isNotEmpty) {
          targetByTitle[service]![cleanTitle] = item;
        }

        final int malId;
        if (mediaType == MediaType.manga) {
          if (service == ServiceType.mal || service == ServiceType.shikimori) {
            malId = item.id;
          } else if (item.malId != null && item.malId! > 0) {
            malId = item.malId!;
          } else {
            malId = mangaMapping?.findMalId(service, item.id) ?? 0;
          }
        } else {
          malId =
              (service == ServiceType.mal || service == ServiceType.shikimori)
              ? item.id
              : (item.malId != null && item.malId! > 0)
              ? item.malId!
              : fribb.findMalId(service, item.id);
        }
        if (malId != 0) {
          targetByMalId[service]![malId] = item;
        }
      }
    }

    final availableTargets = ServiceType.values.where((s) {
      if (s == primaryService) return false;
      if (mediaType == MediaType.manga && s == ServiceType.simkl) return false;
      if (mediaType == MediaType.anime &&
          (s == ServiceType.mangabaka || s == ServiceType.mangaupdates)) {
        return false;
      }
      if (fetchErrors.containsKey(s)) return false;
      return allServiceItems.containsKey(s) &&
          (isServiceConnected(s) || allServiceItems[s]!.isNotEmpty);
    }).toList();

    for (final pItem in primaryItems) {
      final pMalId =
          (primaryService == ServiceType.mal ||
              primaryService == ServiceType.shikimori)
          ? pItem.id
          : (pItem.malId != null && pItem.malId! > 0)
          ? pItem.malId!
          : (mediaType == MediaType.manga
                ? (mangaMapping?.findMalId(primaryService, pItem.id) ?? 0)
                : fribb.findMalId(primaryService, pItem.id));

      for (final targetSvc in availableTargets) {
        MediaItem? existingTarget;

        if (pMalId != 0) {
          existingTarget = targetByMalId[targetSvc]?[pMalId];

          if (existingTarget == null) {
            int targetServiceId = mediaType == MediaType.manga
                ? (mangaMapping?.findTargetId(pMalId, targetSvc) ?? 0)
                : fribb.findTargetId(pMalId, targetSvc);
            if (targetServiceId == 0 &&
                mediaType == MediaType.manga &&
                mangaMapping != null) {
              targetServiceId = await mangaMapping!.findTargetIdWithLookup(
                pMalId,
                targetSvc,
              );
            }
            if (targetServiceId == 0 && mediaType == MediaType.anime) {
              if (targetSvc == ServiceType.anilist) {
                targetServiceId =
                    (await anilist.findMediaIdByMalId(
                      pMalId,
                      MediaType.anime,
                    )) ??
                    0;
              } else if (targetSvc == ServiceType.kitsu) {
                targetServiceId =
                    (await kitsu.findMediaIdByMalId(pMalId, MediaType.anime)) ??
                    0;
              }
            }
            if (targetServiceId != 0) {
              existingTarget = targetByServiceId[targetSvc]?[targetServiceId];
            }
          }
        }

        if (existingTarget == null && primaryService == targetSvc) {
          existingTarget = targetByServiceId[targetSvc]?[pItem.id];
        }
        if (existingTarget == null) {
          final cleanTitle = _normalizeTitle(pItem.title);
          if (cleanTitle.isNotEmpty) {
            existingTarget = targetByTitle[targetSvc]?[cleanTitle];
          }
        }

        if (existingTarget == null) {
          if (onlyExisting) continue;

          if (pMalId <= 0) {
            continue;
          }

          final targetId = await resolveTargetId(
            malId: pMalId,
            targetService: targetSvc,
            mediaType: mediaType,
          );

          if (targetId <= 0) {
            continue;
          }

          final isPrimaryCompleted =
              pItem.status.toLowerCase() == 'completed' ||
              pItem.status.toLowerCase() == 'complete';
          final effectivePrimaryProgress =
              (pItem.service == ServiceType.mangaupdates &&
                  !isPrimaryCompleted &&
                  pItem.progress <= 1)
              ? 0
              : pItem.progress;
          final effectivePrimaryStatus =
              (pItem.service == ServiceType.mangaupdates &&
                  !isPrimaryCompleted &&
                  pItem.progress <= 1 &&
                  pItem.status == 'watching')
              ? 'plan_to_watch'
              : pItem.status;

          actions.add(
            SyncAction(
              targetService: targetSvc,
              targetId: targetId,
              targetMalId: pMalId,
              title: pItem.title,
              posterImage: pItem.posterImage,
              mediaType: mediaType,
              newStatus: effectivePrimaryStatus,
              newScore: pItem.score,
              newProgress: effectivePrimaryProgress,
              isAdd: true,
            ),
          );
        } else {
          final isPrimaryCompleted =
              pItem.status.toLowerCase() == 'completed' ||
              pItem.status.toLowerCase() == 'complete';
          final isTargetCompleted =
              existingTarget.status.toLowerCase() == 'completed' ||
              existingTarget.status.toLowerCase() == 'complete';
          final bothCompleted = isPrimaryCompleted && isTargetCompleted;

          final effectivePrimaryProgress =
              (pItem.service == ServiceType.mangaupdates &&
                  !isPrimaryCompleted &&
                  pItem.progress <= 1)
              ? 0
              : pItem.progress;
          final effectiveTargetProgress =
              (existingTarget.service == ServiceType.mangaupdates &&
                  !isTargetCompleted &&
                  existingTarget.progress <= 1)
              ? 0
              : existingTarget.progress;

          final effectivePrimaryStatus =
              (pItem.service == ServiceType.mangaupdates &&
                  !isPrimaryCompleted &&
                  pItem.progress <= 1 &&
                  pItem.status == 'watching')
              ? 'plan_to_watch'
              : pItem.status;
          final effectiveTargetStatus =
              (existingTarget.service == ServiceType.mangaupdates &&
                  !isTargetCompleted &&
                  existingTarget.progress <= 1 &&
                  existingTarget.status == 'watching')
              ? 'plan_to_watch'
              : existingTarget.status;

          final diffStatus = effectiveTargetStatus != effectivePrimaryStatus;
          final diffScore = existingTarget.score != pItem.score;
          final diffProgress = bothCompleted
              ? false
              : (effectiveTargetProgress != effectivePrimaryProgress);

          if (diffStatus || diffScore || diffProgress) {
            final effectiveNewProgress = bothCompleted
                ? existingTarget.progress
                : (isPrimaryCompleted &&
                          existingTarget.totalProgress != null &&
                          existingTarget.totalProgress! > 0
                      ? existingTarget.totalProgress!
                      : effectivePrimaryProgress);

            actions.add(
              SyncAction(
                targetService: targetSvc,
                targetId: existingTarget.id,
                targetMalId:
                    existingTarget.malId ?? (pMalId != 0 ? pMalId : null),
                title: pItem.title,
                posterImage: pItem.posterImage.isNotEmpty
                    ? pItem.posterImage
                    : existingTarget.posterImage,
                mediaType: mediaType,
                newStatus: effectivePrimaryStatus,
                newScore: pItem.score,
                newProgress: effectiveNewProgress,
                oldStatus: existingTarget.status,
                oldScore: existingTarget.score,
                oldProgress: existingTarget.progress,
                isAdd: false,
              ),
            );
          }
        }
      }
    }

    return actions;
  }

  Future<void> removeItem({
    required ServiceType service,
    required MediaItem item,
    required int malId,
    required String title,
  }) async {
    if (!service.supportsMediaType(item.mediaType)) {
      throw ArgumentError(
        '${service.displayName} does not support this media type.',
      );
    }

    switch (service) {
      case ServiceType.mal:
        await mal.removeItem(id: item.id, type: item.mediaType);
        break;
      case ServiceType.anilist:
        final listEntryId = item.listEntryId;
        if (listEntryId == null || listEntryId <= 0) {
          throw Exception('AniList list entry ID is unavailable.');
        }
        await anilist.removeItem(
          listEntryId: listEntryId,
          type: item.mediaType,
        );
        break;
      case ServiceType.kitsu:
        await kitsu.removeItem(id: item.id, type: item.mediaType);
        break;
      case ServiceType.shikimori:
        await shikimori.removeItem(id: item.id, type: item.mediaType);
        break;
      case ServiceType.simkl:
        await simkl.removeItem(id: item.id, malId: malId, title: title);
        break;
      case ServiceType.mangabaka:
        if (mangabaka == null) {
          throw Exception('MangaBaka service is unavailable.');
        }
        await mangabaka!.removeItem(id: item.id);
        break;
      case ServiceType.mangaupdates:
        if (mangaupdates == null) {
          throw Exception('MangaUpdates service is unavailable.');
        }
        await mangaupdates!.removeItem(id: item.id);
        break;
    }
  }

  Future<bool> executeAction(SyncAction action) async {
    try {
      switch (action.targetService) {
        case ServiceType.mal:
          if (mal.isAuthenticated) {
            await mal.updateItem(
              id: action.targetId,
              type: action.mediaType,
              status: action.newStatus,
              score: action.newScore,
              progress: action.newProgress,
            );
          }
          return true;
        case ServiceType.anilist:
          if (anilist.isAuthenticated) {
            await anilist.updateItem(
              id: action.targetId,
              type: action.mediaType,
              status: action.newStatus,
              score: action.newScore,
              progress: action.newProgress,
            );
          }
          return true;
        case ServiceType.kitsu:
          if (kitsu.isAuthenticated) {
            await kitsu.updateItem(
              id: action.targetId,
              type: action.mediaType,
              status: action.newStatus,
              score: action.newScore,
              progress: action.newProgress,
            );
          }
          return true;
        case ServiceType.shikimori:
          if (shikimori.isAuthenticated) {
            await shikimori.updateItem(
              id: action.targetId,
              type: action.mediaType,
              status: action.newStatus,
              score: action.newScore,
              progress: action.newProgress,
            );
          }
          return true;
        case ServiceType.simkl:
          if (simkl.isAuthenticated) {
            int simklId = action.targetId;
            int? malId = action.targetMalId;
            if (malId == null || malId == 0) {
              final mappedMalId = fribb.findMalId(
                ServiceType.simkl,
                action.targetId,
              );
              if (mappedMalId != 0) {
                malId = mappedMalId;
              } else {
                final mappedSimkl = fribb.findTargetId(
                  action.targetId,
                  ServiceType.simkl,
                );
                if (mappedSimkl != 0) {
                  simklId = mappedSimkl;
                  malId = action.targetId;
                }
              }
            }

            await simkl.updateItem(
              id: simklId,
              malId: malId,
              title: action.title,
              type: action.mediaType,
              status: action.newStatus,
              score: action.newScore,
              progress: action.newProgress,
              oldProgress: action.oldProgress,
              oldScore: action.oldScore,
            );
          }
          return true;
        case ServiceType.mangabaka:
          if (mangabaka != null && mangabaka!.isAuthenticated) {
            await mangabaka!.updateItem(
              id: action.targetId,
              type: action.mediaType,
              status: action.newStatus,
              score: action.newScore,
              progress: action.newProgress,
            );
          }
          return true;
        case ServiceType.mangaupdates:
          if (mangaupdates != null && mangaupdates!.isAuthenticated) {
            await mangaupdates!.updateItem(
              id: action.targetId,
              type: action.mediaType,
              status: action.newStatus,
              score: action.newScore,
              progress: action.newProgress,
            );
          }
          return true;
      }
    } catch (e, st) {
      debugPrint(
        'SyncEngine executeAction error for ${action.targetService} ("${action.title}"): $e\n$st',
      );
      return false;
    }
  }
}
