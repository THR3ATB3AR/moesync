import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../services/anilist_service.dart';
import '../services/fribb_mapping_service.dart';
import '../services/kitsu_service.dart';
import '../services/mal_service.dart';
import '../services/manga_mapping_service.dart';
import '../services/mangabaka_service.dart';
import '../services/mangaupdates_service.dart';
import '../services/media_detail_service.dart';
import '../services/oauth_service.dart';
import '../services/shikimori_service.dart';
import '../services/simkl_service.dart';
import '../services/storage_service.dart';
import '../services/sync_engine.dart';
import '../theme.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Initialize storageServiceProvider in main');
});

final oauthServiceProvider = Provider<OAuthService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return OAuthService(storage);
});

final fribbServiceProvider = Provider<FribbMappingService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FribbMappingService(storage);
});

final malServiceProvider = Provider<MalService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final oauth = ref.watch(oauthServiceProvider);
  return MalService(storage, oauth: oauth);
});

final anilistServiceProvider = Provider<AnilistService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AnilistService(storage);
});

final kitsuServiceProvider = Provider<KitsuService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return KitsuService(storage);
});

final shikimoriServiceProvider = Provider<ShikimoriService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final oauth = ref.watch(oauthServiceProvider);
  return ShikimoriService(storage, oauth: oauth);
});

final simklServiceProvider = Provider<SimklService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SimklService(storage);
});

final mangabakaServiceProvider = Provider<MangaBakaService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final oauth = ref.watch(oauthServiceProvider);
  return MangaBakaService(storage, oauth: oauth);
});

final mangaupdatesServiceProvider = Provider<MangaUpdatesService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MangaUpdatesService(storage);
});

final mangaMappingServiceProvider = Provider<MangaMappingService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final mangabaka = ref.watch(mangabakaServiceProvider);
  return MangaMappingService(storage, mangabaka);
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    mal: ref.watch(malServiceProvider),
    anilist: ref.watch(anilistServiceProvider),
    kitsu: ref.watch(kitsuServiceProvider),
    shikimori: ref.watch(shikimoriServiceProvider),
    simkl: ref.watch(simklServiceProvider),
    fribb: ref.watch(fribbServiceProvider),
    mangabaka: ref.watch(mangabakaServiceProvider),
    mangaupdates: ref.watch(mangaupdatesServiceProvider),
    mangaMapping: ref.watch(mangaMappingServiceProvider),
  );
});

final mediaDetailServiceProvider = Provider<MediaDetailService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final fribb = ref.watch(fribbServiceProvider);
  final mangaMapping = ref.watch(mangaMappingServiceProvider);
  return MediaDetailService(storage, fribb, mangaMapping);
});

class AuthState {
  final Map<ServiceType, ServiceCredentials> credentials;
  const AuthState({required this.credentials});

  bool isConnected(ServiceType service) =>
      credentials[service]?.isConnected == true ||
      (credentials[service]?.accessToken?.isNotEmpty ?? false);

  int get connectedCount =>
      ServiceType.values.where((s) => isConnected(s)).length;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final storage = ref.watch(storageServiceProvider);
    void listener(ServiceType s, ServiceCredentials c) {
      final updated = Map<ServiceType, ServiceCredentials>.from(
        state.credentials,
      );
      updated[s] = c;
      state = AuthState(credentials: updated);
    }

    storage.addCredentialsListener(listener);
    ref.onDispose(() => storage.removeCredentialsListener(listener));

    return AuthState(
      credentials: {
        for (final s in ServiceType.values) s: storage.getCredentials(s),
      },
    );
  }

  Future<void> saveCredentials(
    ServiceType service,
    ServiceCredentials creds,
  ) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveCredentials(service, creds);
    final updated = Map<ServiceType, ServiceCredentials>.from(
      state.credentials,
    );
    updated[service] = creds;
    state = AuthState(credentials: updated);
  }

  Future<void> disconnect(ServiceType service) async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearCredentials(service);
    if (service == ServiceType.simkl) {
      ref.read(simklServiceProvider).clearCache();
    }
    if (service == ServiceType.mangaupdates) {
      ref.read(mangaupdatesServiceProvider).clearCache();
    }
    if (service == ServiceType.anilist) {
      ref.read(anilistServiceProvider).clearCache();
    }
    ref.read(mediaLibraryProvider.notifier).clearServiceError(service);
    ref.read(syncProvider.notifier).clearServiceError(service);

    final updated = Map<ServiceType, ServiceCredentials>.from(
      state.credentials,
    );
    updated[service] = storage.getCredentials(service);
    state = AuthState(credentials: updated);
  }

  Future<void> disconnectAll() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearAllCredentials();
    ref.read(simklServiceProvider).clearCache();
    ref.read(mangaupdatesServiceProvider).clearCache();
    ref.read(anilistServiceProvider).clearCache();
    ref.read(mediaLibraryProvider.notifier).clearAllServiceErrors();
    ref.read(syncProvider.notifier).clearAllServiceErrors();

    state = AuthState(
      credentials: {
        for (final s in ServiceType.values) s: storage.getCredentials(s),
      },
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class MediaLibraryState {
  final MediaType selectedType;
  final String statusFilter;
  final ServiceType? serviceFilter;
  final String searchQuery;
  final bool isLoading;
  final List<UnifiedMediaItem> unifiedItems;
  final String? errorMessage;
  final Map<ServiceType, String> serviceErrors;
  final Map<(MediaType, int), int> pendingProgressDeltas;

  const MediaLibraryState({
    this.selectedType = MediaType.anime,
    this.statusFilter = 'all',
    this.serviceFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.unifiedItems = const [],
    this.errorMessage,
    this.serviceErrors = const {},
    this.pendingProgressDeltas = const {},
  });

  MediaLibraryState copyWith({
    MediaType? selectedType,
    String? statusFilter,
    ServiceType? serviceFilter,
    bool clearServiceFilter = false,
    String? searchQuery,
    bool? isLoading,
    List<UnifiedMediaItem>? unifiedItems,
    String? errorMessage,
    Map<ServiceType, String>? serviceErrors,
    Map<(MediaType, int), int>? pendingProgressDeltas,
  }) {
    return MediaLibraryState(
      selectedType: selectedType ?? this.selectedType,
      statusFilter: statusFilter ?? this.statusFilter,
      serviceFilter: clearServiceFilter
          ? null
          : (serviceFilter ?? this.serviceFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      unifiedItems: unifiedItems ?? this.unifiedItems,
      errorMessage: errorMessage,
      serviceErrors: serviceErrors ?? this.serviceErrors,
      pendingProgressDeltas:
          pendingProgressDeltas ?? this.pendingProgressDeltas,
    );
  }

  List<UnifiedMediaItem> get filteredItems {
    return unifiedItems.where((u) {
      if (u.mediaType != selectedType) return false;

      if (!u.matchesTitleQuery(searchQuery)) {
        return false;
      }

      if (serviceFilter != null && !u.services.containsKey(serviceFilter)) {
        return false;
      }

      if (statusFilter != 'all') {
        final hasStatus = u.services.values.any(
          (item) => item.status.toLowerCase() == statusFilter.toLowerCase(),
        );
        if (!hasStatus) return false;
      }

      return true;
    }).toList();
  }
}

class MediaLibraryNotifier extends Notifier<MediaLibraryState> {
  final Map<(MediaType, int), Timer> _progressUpdateTimers = {};
  final Map<(MediaType, int), int> _progressBeforeChanges = {};
  final Map<(MediaType, int), UnifiedMediaItem> _itemsBeingUpdated = {};

  @override
  MediaLibraryState build() {
    ref.onDispose(() {
      for (final timer in _progressUpdateTimers.values) {
        timer.cancel();
      }
    });
    Future.microtask(() => loadItems());
    return const MediaLibraryState();
  }

  Future<void> loadItems({bool forceRefresh = false}) async {
    final engine = ref.read(syncEngineProvider);
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final animeErrors = <ServiceType, String>{};
      final mangaErrors = <ServiceType, String>{};
      final results = await Future.wait([
        engine.buildUnifiedList(
          MediaType.anime,
          forceRefresh: forceRefresh,
          errorsOut: animeErrors,
          onItemsLoaded: (items) => _updateItemsForType(MediaType.anime, items),
        ),
        engine.buildUnifiedList(
          MediaType.manga,
          forceRefresh: forceRefresh,
          errorsOut: mangaErrors,
          onItemsLoaded: (items) => _updateItemsForType(MediaType.manga, items),
        ),
      ]);
      state = state.copyWith(
        isLoading: false,
        unifiedItems: [...results[0], ...results[1]],
        serviceErrors: {...animeErrors, ...mangaErrors},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load library: $e',
      );
    }
  }

  void _updateItemsForType(MediaType type, List<UnifiedMediaItem> items) {
    state = state.copyWith(
      unifiedItems: [
        ...state.unifiedItems.where((item) => item.mediaType != type),
        ...items,
      ],
    );
  }

  void setType(MediaType type) {
    state = state.copyWith(selectedType: type);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void setServiceFilter(ServiceType? service) {
    if (service == null) {
      state = state.copyWith(clearServiceFilter: true);
    } else {
      state = state.copyWith(serviceFilter: service);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void queueProgressChange(UnifiedMediaItem item, int delta) {
    final itemId = (item.mediaType, item.malId);
    final pendingDelta = state.pendingProgressDeltas[itemId] ?? 0;
    final progress =
        _progressBeforeChanges[itemId] ??
        item.services.values.firstOrNull?.progress ??
        0;
    if (progress + pendingDelta + delta < 0) return;

    _progressBeforeChanges.putIfAbsent(itemId, () => progress);
    _itemsBeingUpdated.putIfAbsent(itemId, () => item);
    final updatedPendingDeltas = Map<(MediaType, int), int>.from(
      state.pendingProgressDeltas,
    );
    final nextPendingDelta = pendingDelta + delta;
    if (nextPendingDelta == 0) {
      updatedPendingDeltas.remove(itemId);
    } else {
      updatedPendingDeltas[itemId] = nextPendingDelta;
    }
    state = state.copyWith(pendingProgressDeltas: updatedPendingDeltas);

    _progressUpdateTimers[itemId]?.cancel();
    _progressUpdateTimers[itemId] = Timer(const Duration(seconds: 1), () {
      _progressUpdateTimers.remove(itemId);
      final initialProgress = _progressBeforeChanges.remove(itemId);
      final itemBeingUpdated = _itemsBeingUpdated.remove(itemId);
      final finalDelta = state.pendingProgressDeltas[itemId] ?? 0;
      final remainingPendingDeltas = Map<(MediaType, int), int>.from(
        state.pendingProgressDeltas,
      )..remove(itemId);
      state = state.copyWith(pendingProgressDeltas: remainingPendingDeltas);

      if (initialProgress != null &&
          itemBeingUpdated != null &&
          finalDelta != 0) {
        updateProgress(itemBeingUpdated, initialProgress + finalDelta);
      }
    });
  }

  Future<void> updateProgress(UnifiedMediaItem item, int newProgress) async {
    final clampedProgress = newProgress.clamp(0, 99999);
    final engine = ref.read(syncEngineProvider);
    final pendingFutures = <Future<bool>>[];

    final total = item.resolvedTotalProgress;

    final updatedList = state.unifiedItems.map((u) {
      if (u.malId == item.malId && u.mediaType == item.mediaType) {
        final updatedServices = Map<ServiceType, MediaItem>.from(u.services);

        for (final entry in updatedServices.entries) {
          final oldProg = entry.value.progress;
          final oldStatus = entry.value.status;
          final activeStatus = u.mediaType == MediaType.anime
              ? 'watching'
              : 'reading';
          final newStatus = (total != null && clampedProgress >= total)
              ? 'completed'
              : oldProg == 0 && clampedProgress > 0
              ? activeStatus
              : oldStatus;

          updatedServices[entry.key] = entry.value.copyWith(
            progress: clampedProgress,
            status: newStatus,
          );

          pendingFutures.add(
            engine.executeAction(
              SyncAction(
                targetService: entry.key,
                targetId: entry.value.id,
                title: u.title,
                posterImage: u.posterImage,
                mediaType: u.mediaType,
                newStatus: newStatus,
                newScore: entry.value.score,
                newProgress: clampedProgress,
                oldProgress: oldProg,
                oldStatus: oldStatus,
                oldScore: entry.value.score,
                isAdd: false,
              ),
            ),
          );
        }

        return u.copyWith(services: updatedServices);
      }
      return u;
    }).toList();

    state = state.copyWith(unifiedItems: updatedList);
    await Future.wait(pendingFutures);
  }

  Future<void> updateItemDetails({
    required UnifiedMediaItem item,
    required String status,
    required int score,
    required int progress,
    Map<ServiceType, String> serviceStatuses = const {},
    Map<ServiceType, int> serviceProgresses = const {},
    Set<ServiceType>? servicesToUpdate,
  }) async {
    final engine = ref.read(syncEngineProvider);
    final pendingFutures = <Future<bool>>[];
    Map<ServiceType, MediaItem> servicesToCommit = {};

    final existingIndex = state.unifiedItems.indexWhere(
      (u) =>
          u.mediaType == item.mediaType &&
          ((item.malId > 0 && u.malId == item.malId) ||
              u.title.toLowerCase() == item.title.toLowerCase()),
    );

    if (existingIndex >= 0) {
      final u = state.unifiedItems[existingIndex];
      final updatedServices = Map<ServiceType, MediaItem>.from(u.services);
      final targetServices = servicesToUpdate ?? u.services.keys.toSet();
      for (final service in targetServices) {
        final existingServiceItem = updatedServices[service];
        final sourceServiceItem = item.services[service];
        final serviceItem = existingServiceItem ?? sourceServiceItem;
        if (serviceItem == null) continue;

        final oldProg = serviceItem.progress;
        final oldStat = serviceItem.status;
        final oldSc = serviceItem.score;
        final serviceStatus = serviceStatuses[service] ?? status;
        final serviceProgress = serviceProgresses[service] ?? progress;
        updatedServices[service] = serviceItem.copyWith(
          status: serviceStatus,
          score: score,
          progress: serviceProgress,
        );
        pendingFutures.add(
          engine.executeAction(
            SyncAction(
              targetService: service,
              targetId: serviceItem.id,
              targetMalId: serviceItem.malId ?? (u.malId != 0 ? u.malId : null),
              title: u.title,
              posterImage: u.posterImage,
              mediaType: u.mediaType,
              newStatus: serviceStatus,
              newScore: score,
              newProgress: serviceProgress,
              oldProgress: oldProg,
              oldStatus: oldStat,
              oldScore: oldSc,
              isAdd: existingServiceItem == null,
            ),
          ),
        );
      }
      servicesToCommit = updatedServices;
    } else {
      final updatedServices = Map<ServiceType, MediaItem>.from(item.services);
      final targetServices = servicesToUpdate ?? item.services.keys.toSet();
      for (final service in targetServices) {
        final serviceItem = updatedServices[service];
        if (serviceItem == null) continue;
        final oldProg = serviceItem.progress;
        final oldStat = serviceItem.status;
        final oldSc = serviceItem.score;
        final serviceStatus = serviceStatuses[service] ?? status;
        final serviceProgress = serviceProgresses[service] ?? progress;
        updatedServices[service] = serviceItem.copyWith(
          status: serviceStatus,
          score: score,
          progress: serviceProgress,
        );
        pendingFutures.add(
          engine.executeAction(
            SyncAction(
              targetService: service,
              targetId: serviceItem.id,
              targetMalId:
                  serviceItem.malId ?? (item.malId != 0 ? item.malId : null),
              title: item.title,
              posterImage: item.posterImage,
              mediaType: item.mediaType,
              newStatus: serviceStatus,
              newScore: score,
              newProgress: serviceProgress,
              oldProgress: oldProg,
              oldStatus: oldStat,
              oldScore: oldSc,
              isAdd: true,
            ),
          ),
        );
      }
      servicesToCommit = updatedServices;
    }

    final results = await Future.wait(pendingFutures);
    if (results.any((success) => !success)) {
      throw Exception('Failed to update one or more connected services.');
    }

    final latestIndex = state.unifiedItems.indexWhere(
      (u) =>
          u.mediaType == item.mediaType &&
          ((item.malId > 0 && u.malId == item.malId) ||
              u.title.toLowerCase() == item.title.toLowerCase()),
    );
    final updatedItems = List<UnifiedMediaItem>.from(state.unifiedItems);
    if (latestIndex >= 0) {
      final latestItem = updatedItems[latestIndex];
      updatedItems[latestIndex] = latestItem.copyWith(
        services: {...latestItem.services, ...servicesToCommit},
      );
    } else {
      updatedItems.insert(0, item.copyWith(services: servicesToCommit));
    }
    state = state.copyWith(unifiedItems: updatedItems);
  }

  Future<void> addItemToAllServices({
    required UnifiedMediaItem item,
    required String status,
    required int score,
    required int progress,
  }) async {
    final engine = ref.read(syncEngineProvider);
    var malId = item.malId > 0
        ? item.malId
        : (item.services[ServiceType.mal]?.id ??
              item.services[ServiceType.shikimori]?.id ??
              item.services.values
                  .map((serviceItem) => serviceItem.malId ?? 0)
                  .firstWhere((id) => id > 0, orElse: () => 0));

    if (malId <= 0 && item.services.isNotEmpty) {
      final mal = ref.read(malServiceProvider);
      final source = item.services.values.first;
      final normalizedTitle = _normalizeMediaTitle(item.title);
      final malResults = await mal.search(item.title, item.mediaType);
      for (final result in malResults) {
        final titles = [
          result.title,
          result.englishTitle,
          result.japaneseTitle,
          result.romajiTitle,
          ...result.alternativeTitles,
        ].whereType<String>();
        if (titles.any(
          (title) =>
              title.trim().toLowerCase() == item.title.trim().toLowerCase() ||
              (normalizedTitle.isNotEmpty &&
                  _normalizeMediaTitle(title) == normalizedTitle),
        )) {
          malId = result.id;
          break;
        }
      }
      if (malId <= 0 &&
          (source.service == ServiceType.mal ||
              source.service == ServiceType.shikimori)) {
        malId = source.id;
      }
    }

    final existingIndex = state.unifiedItems.indexWhere(
      (candidate) =>
          candidate.mediaType == item.mediaType &&
          ((malId > 0 && candidate.malId == malId) ||
              candidate.title.toLowerCase() == item.title.toLowerCase()),
    );
    final existingServices = existingIndex >= 0
        ? state.unifiedItems[existingIndex].services
        : const <ServiceType, MediaItem>{};
    final targetServices = <ServiceType, MediaItem>{};
    for (final service in ServiceType.forMediaType(item.mediaType)) {
      if (!engine.isServiceConnected(service)) continue;

      final existing = existingServices[service] ?? item.services[service];
      final targetId =
          existing?.id ??
          (malId > 0
              ? await engine.resolveTargetId(
                  malId: malId,
                  targetService: service,
                  mediaType: item.mediaType,
                )
              : 0);
      if (targetId <= 0) continue;

      targetServices[service] =
          (existing ??
                  MediaItem(
                    id: targetId,
                    malId: malId > 0 ? malId : null,
                    title: item.title,
                    status: status,
                    score: score,
                    progress: progress,
                    totalProgress: item.resolvedTotalProgress,
                    posterImage: item.posterImage,
                    service: service,
                    mediaType: item.mediaType,
                  ))
              .copyWith(
                id: targetId,
                malId: malId > 0 ? malId : existing?.malId,
                status: status,
                score: score,
                progress: progress,
              );
    }

    if (targetServices.isEmpty) {
      throw Exception(
        malId > 0
            ? 'No connected service could resolve this title.'
            : 'This title could not be matched to a MyAnimeList ID.',
      );
    }

    final unifiedItem = UnifiedMediaItem(
      malId: malId,
      title: item.title,
      posterImage: item.posterImage,
      mediaType: item.mediaType,
      services: targetServices,
    );
    await updateItemDetails(
      item: unifiedItem,
      status: status,
      score: score,
      progress: progress,
      servicesToUpdate: targetServices.keys.toSet(),
    );
  }

  String _normalizeMediaTitle(String title) =>
      title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> removeItemFromAllServices(UnifiedMediaItem item) async {
    final libraryIndex = state.unifiedItems.indexWhere(
      (candidate) =>
          candidate.mediaType == item.mediaType &&
          ((item.malId > 0 && candidate.malId == item.malId) ||
              candidate.title.toLowerCase() == item.title.toLowerCase()),
    );
    if (libraryIndex < 0) return;

    final libraryItem = state.unifiedItems[libraryIndex];
    if (libraryItem.services.isEmpty) return;

    final engine = ref.read(syncEngineProvider);
    final results = await Future.wait(
      libraryItem.services.entries.map((entry) async {
        try {
          await engine.removeItem(
            service: entry.key,
            item: entry.value,
            malId: libraryItem.malId,
            title: libraryItem.title,
          );
          return (service: entry.key, error: null as Object?);
        } catch (error) {
          return (service: entry.key, error: error);
        }
      }),
    );

    final removedServices = results
        .where((result) => result.error == null)
        .map((result) => result.service)
        .toSet();
    final errors = results
        .where((result) => result.error != null)
        .map(
          (result) =>
              '${result.service.displayName}: ${result.error}',
        )
        .toList();
    final updatedServices = Map<ServiceType, MediaItem>.from(
      libraryItem.services,
    )..removeWhere((service, _) => removedServices.contains(service));
    final updatedItems = List<UnifiedMediaItem>.from(state.unifiedItems);
    if (updatedServices.isEmpty) {
      updatedItems.removeAt(libraryIndex);
    } else {
      updatedItems[libraryIndex] = libraryItem.copyWith(
        services: updatedServices,
      );
    }
    state = state.copyWith(unifiedItems: updatedItems);

    if (errors.isNotEmpty) {
      throw Exception('Some services could not remove the item: ${errors.join('; ')}');
    }
  }

  void clearServiceError(ServiceType service) {
    if (state.serviceErrors.containsKey(service)) {
      final updated = Map<ServiceType, String>.from(state.serviceErrors)
        ..remove(service);
      state = state.copyWith(serviceErrors: updated);
    }
  }

  void clearAllServiceErrors() {
    if (state.serviceErrors.isNotEmpty) {
      state = state.copyWith(serviceErrors: const {});
    }
  }
}

final mediaLibraryProvider =
    NotifierProvider<MediaLibraryNotifier, MediaLibraryState>(
      MediaLibraryNotifier.new,
    );

class SyncState {
  final ServiceType primaryService;
  final MediaType mediaType;
  final bool onlyExisting;
  final bool isScanning;
  final bool isSyncing;
  final List<SyncAction> pendingActions;
  final int syncedCount;
  final int totalToSync;
  final String? statusMessage;
  final List<String> syncLog;
  final Map<ServiceType, String> serviceErrors;

  const SyncState({
    this.primaryService = ServiceType.mal,
    this.mediaType = MediaType.anime,
    this.onlyExisting = false,
    this.isScanning = false,
    this.isSyncing = false,
    this.pendingActions = const [],
    this.syncedCount = 0,
    this.totalToSync = 0,
    this.statusMessage,
    this.syncLog = const [],
    this.serviceErrors = const {},
  });

  SyncState copyWith({
    ServiceType? primaryService,
    MediaType? mediaType,
    bool? onlyExisting,
    bool? isScanning,
    bool? isSyncing,
    List<SyncAction>? pendingActions,
    int? syncedCount,
    int? totalToSync,
    String? statusMessage,
    List<String>? syncLog,
    Map<ServiceType, String>? serviceErrors,
  }) {
    return SyncState(
      primaryService: primaryService ?? this.primaryService,
      mediaType: mediaType ?? this.mediaType,
      onlyExisting: onlyExisting ?? this.onlyExisting,
      isScanning: isScanning ?? this.isScanning,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingActions: pendingActions ?? this.pendingActions,
      syncedCount: syncedCount ?? this.syncedCount,
      totalToSync: totalToSync ?? this.totalToSync,
      statusMessage: statusMessage,
      syncLog: syncLog ?? this.syncLog,
      serviceErrors: serviceErrors ?? this.serviceErrors,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    final storage = ref.watch(storageServiceProvider);
    final onlyExisting = storage.getSyncOnlyExisting();
    final initialSync = storage.getDefaultSyncSource(MediaType.anime);
    Future.microtask(() => scanDiffs());
    return SyncState(primaryService: initialSync, onlyExisting: onlyExisting);
  }

  void setPrimary(ServiceType service) {
    state = state.copyWith(primaryService: service);
    scanDiffs();
  }

  void setMediaType(MediaType type) {
    final storage = ref.read(storageServiceProvider);
    final defaultPrimary = storage.getDefaultSyncSource(type);
    state = state.copyWith(mediaType: type, primaryService: defaultPrimary);
    scanDiffs();
  }

  Future<void> setOnlyExisting(bool value) async {
    state = state.copyWith(onlyExisting: value);
    final storage = ref.read(storageServiceProvider);
    await storage.setSyncOnlyExisting(value);
    scanDiffs();
  }

  void toggleAction(int index) {
    final updated = List<SyncAction>.from(state.pendingActions);
    updated[index].isSelected = !updated[index].isSelected;
    state = state.copyWith(pendingActions: updated);
  }

  void selectAll(bool select) {
    final updated = List<SyncAction>.from(state.pendingActions);
    for (final a in updated) {
      a.isSelected = select;
    }
    state = state.copyWith(pendingActions: updated);
  }

  Future<void> scanDiffs({bool forceRefresh = false}) async {
    if (!ref.mounted) return;
    final engine = ref.read(syncEngineProvider);
    state = state.copyWith(
      isScanning: true,
      pendingActions: const [],
      statusMessage: 'Scanning lists from connected services...',
    );

    final fetchErrors = <ServiceType, String>{};
    try {
      final actions = await engine.computeSyncActions(
        primaryService: state.primaryService,
        mediaType: state.mediaType,
        onlyExisting: state.onlyExisting,
        forceRefresh: forceRefresh,
        errorsOut: fetchErrors,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        isScanning: false,
        pendingActions: actions,
        serviceErrors: fetchErrors,
        statusMessage: actions.isEmpty
            ? 'Everything is already in sync with ${state.primaryService.displayName}!'
            : 'Found ${actions.length} pending actions to sync.',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Error scanning: $e',
        serviceErrors: fetchErrors,
      );
    }
  }

  Future<void> executeSync() async {
    final engine = ref.read(syncEngineProvider);
    final selected = state.pendingActions.where((a) => a.isSelected).toList();
    if (selected.isEmpty) return;

    state = state.copyWith(
      isSyncing: true,
      syncedCount: 0,
      totalToSync: selected.length,
      statusMessage: 'Synchronizing ${selected.length} items...',
      syncLog: [],
    );

    final logs = <String>[];
    int completed = 0;

    for (final action in selected) {
      final success = await engine.executeAction(action);
      completed++;
      final op = action.isAdd ? 'ADD' : 'UPDATE';
      final statusText = success ? '✓ OK' : '✗ Failed';
      logs.add(
        '[$statusText] $op "${action.title}" on ${action.targetService.displayName}',
      );

      state = state.copyWith(syncedCount: completed, syncLog: List.from(logs));
    }

    state = state.copyWith(
      isSyncing: false,
      statusMessage: 'Completed synchronization of $completed items!',
    );

    ref.read(mediaLibraryProvider.notifier).loadItems();
    await scanDiffs();
  }

  void clearServiceError(ServiceType service) {
    if (state.serviceErrors.containsKey(service)) {
      final updated = Map<ServiceType, String>.from(state.serviceErrors)
        ..remove(service);
      state = state.copyWith(serviceErrors: updated);
    }
  }

  void clearAllServiceErrors() {
    if (state.serviceErrors.isNotEmpty) {
      state = state.copyWith(serviceErrors: const {});
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

final serviceErrorsProvider = Provider<Map<ServiceType, String>>((ref) {
  final libErrors = ref.watch(mediaLibraryProvider).serviceErrors;
  final syncErrors = ref.watch(syncProvider).serviceErrors;
  final combined = Map<ServiceType, String>.from(libErrors);
  for (final e in syncErrors.entries) {
    combined[e.key] = e.value;
  }
  return combined;
});

class ServiceDisplayStyleNotifier extends Notifier<ServiceDisplayStyle> {
  @override
  ServiceDisplayStyle build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getServiceDisplayStyle();
  }

  Future<void> setStyle(ServiceDisplayStyle style) async {
    state = style;
    final storage = ref.read(storageServiceProvider);
    await storage.setServiceDisplayStyle(style);
  }
}

final serviceDisplayStyleProvider =
    NotifierProvider<ServiceDisplayStyleNotifier, ServiceDisplayStyle>(
      ServiceDisplayStyleNotifier.new,
    );

class LanguageSettings {
  final String? appLanguageCode;
  final TitleLanguage titleLanguage;

  const LanguageSettings({
    this.appLanguageCode,
    this.titleLanguage = TitleLanguage.source,
  });

  Locale? get locale =>
      appLanguageCode == null ? null : Locale(appLanguageCode!);
}

class LanguageSettingsNotifier extends Notifier<LanguageSettings> {
  @override
  LanguageSettings build() {
    final storage = ref.watch(storageServiceProvider);
    return LanguageSettings(
      appLanguageCode: storage.getAppLanguage(),
      titleLanguage: storage.getTitleLanguage(),
    );
  }

  Future<void> setAppLanguage(String? languageCode) async {
    await ref.read(storageServiceProvider).setAppLanguage(languageCode);
    state = LanguageSettings(
      appLanguageCode: languageCode,
      titleLanguage: state.titleLanguage,
    );
  }

  Future<void> setTitleLanguage(TitleLanguage language) async {
    await ref.read(storageServiceProvider).setTitleLanguage(language);
    state = LanguageSettings(
      appLanguageCode: state.appLanguageCode,
      titleLanguage: language,
    );
  }
}

final languageSettingsProvider =
    NotifierProvider<LanguageSettingsNotifier, LanguageSettings>(
      LanguageSettingsNotifier.new,
    );

class MediaViewModeNotifier extends Notifier<MediaViewMode> {
  @override
  MediaViewMode build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getMediaViewMode();
  }

  Future<void> setMode(MediaViewMode mode) async {
    state = mode;
    final storage = ref.read(storageServiceProvider);
    await storage.setMediaViewMode(mode);
  }
}

final mediaViewModeProvider =
    NotifierProvider<MediaViewModeNotifier, MediaViewMode>(
      MediaViewModeNotifier.new,
    );

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    final storage = ref.watch(storageServiceProvider);
    return ThemeSettings(
      themeMode: storage.getThemeMode(),
      useDynamicColor: storage.getUseDynamicColor(),
      seedColor: storage.getSeedColor(),
      schemeVariant: storage.getSchemeVariant(),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(storageServiceProvider).setThemeMode(mode);
  }

  Future<void> setUseDynamicColor(bool use) async {
    state = state.copyWith(useDynamicColor: use);
    await ref.read(storageServiceProvider).setUseDynamicColor(use);
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color, useDynamicColor: false);
    await ref.read(storageServiceProvider).setSeedColor(color);
    await ref.read(storageServiceProvider).setUseDynamicColor(false);
  }

  Future<void> setSchemeVariant(DynamicSchemeVariant variant) async {
    state = state.copyWith(schemeVariant: variant);
    await ref.read(storageServiceProvider).setSchemeVariant(variant);
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );

class MediaFilterState {
  final String status;
  final ServiceType? service;
  final String searchQuery;
  final MediaSortField sortField;
  final SortDirection sortDirection;

  const MediaFilterState({
    required this.status,
    this.service,
    this.searchQuery = '',
    this.sortField = MediaSortField.updatedAt,
    this.sortDirection = SortDirection.descending,
  });

  MediaFilterState copyWith({
    String? status,
    ServiceType? service,
    bool clearService = false,
    String? searchQuery,
    MediaSortField? sortField,
    SortDirection? sortDirection,
  }) {
    return MediaFilterState(
      status: status ?? this.status,
      service: clearService ? null : (service ?? this.service),
      searchQuery: searchQuery ?? this.searchQuery,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}

class MediaFilterNotifier extends Notifier<MediaFilterState> {
  final String initialStatus;

  MediaFilterNotifier(this.initialStatus);

  @override
  MediaFilterState build() {
    return MediaFilterState(status: initialStatus);
  }

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void setService(ServiceType? service) {
    if (service == null) {
      state = state.copyWith(clearService: true);
    } else {
      state = state.copyWith(service: service);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSort(MediaSortField field, {SortDirection? direction}) {
    if (direction != null) {
      state = state.copyWith(sortField: field, sortDirection: direction);
    } else if (state.sortField == field) {
      state = state.copyWith(
        sortDirection: state.sortDirection == SortDirection.descending
            ? SortDirection.ascending
            : SortDirection.descending,
      );
    } else {
      final defaultDirection = field == MediaSortField.title
          ? SortDirection.ascending
          : SortDirection.descending;
      state = state.copyWith(sortField: field, sortDirection: defaultDirection);
    }
  }

  void reset() {
    state = MediaFilterState(status: initialStatus);
  }
}

final animeFilterProvider =
    NotifierProvider<MediaFilterNotifier, MediaFilterState>(
      () => MediaFilterNotifier('watching'),
    );

final mangaFilterProvider =
    NotifierProvider<MediaFilterNotifier, MediaFilterState>(
      () => MediaFilterNotifier('reading'),
    );

class DataSourceSettings {
  final ServiceType animeInfoSource;
  final ServiceType mangaInfoSource;
  final ServiceType? animeDescriptionSource;
  final ServiceType? mangaDescriptionSource;
  final ServiceType animeSyncSource;
  final ServiceType mangaSyncSource;

  const DataSourceSettings({
    this.animeInfoSource = ServiceType.mal,
    this.mangaInfoSource = ServiceType.mal,
    this.animeDescriptionSource,
    this.mangaDescriptionSource,
    this.animeSyncSource = ServiceType.mal,
    this.mangaSyncSource = ServiceType.mal,
  });

  ServiceType getInfoSource(MediaType type) =>
      type == MediaType.anime ? animeInfoSource : mangaInfoSource;

  ServiceType? getDescriptionSource(MediaType type) =>
      type == MediaType.anime ? animeDescriptionSource : mangaDescriptionSource;

  ServiceType getSyncSource(MediaType type) =>
      type == MediaType.anime ? animeSyncSource : mangaSyncSource;

  DataSourceSettings copyWith({
    ServiceType? animeInfoSource,
    ServiceType? mangaInfoSource,
    ServiceType? Function()? animeDescriptionSource,
    ServiceType? Function()? mangaDescriptionSource,
    ServiceType? animeSyncSource,
    ServiceType? mangaSyncSource,
  }) {
    return DataSourceSettings(
      animeInfoSource: animeInfoSource ?? this.animeInfoSource,
      mangaInfoSource: mangaInfoSource ?? this.mangaInfoSource,
      animeDescriptionSource: animeDescriptionSource != null
          ? animeDescriptionSource()
          : this.animeDescriptionSource,
      mangaDescriptionSource: mangaDescriptionSource != null
          ? mangaDescriptionSource()
          : this.mangaDescriptionSource,
      animeSyncSource: animeSyncSource ?? this.animeSyncSource,
      mangaSyncSource: mangaSyncSource ?? this.mangaSyncSource,
    );
  }
}

class DataSourceSettingsNotifier extends Notifier<DataSourceSettings> {
  @override
  DataSourceSettings build() {
    final storage = ref.watch(storageServiceProvider);
    return DataSourceSettings(
      animeInfoSource: storage.getDefaultInfoSource(MediaType.anime),
      mangaInfoSource: storage.getDefaultInfoSource(MediaType.manga),
      animeDescriptionSource: storage.getDefaultDescriptionSource(
        MediaType.anime,
      ),
      mangaDescriptionSource: storage.getDefaultDescriptionSource(
        MediaType.manga,
      ),
      animeSyncSource: storage.getDefaultSyncSource(MediaType.anime),
      mangaSyncSource: storage.getDefaultSyncSource(MediaType.manga),
    );
  }

  Future<void> setInfoSource(MediaType type, ServiceType service) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setDefaultInfoSource(type, service);
    state = type == MediaType.anime
        ? state.copyWith(animeInfoSource: service)
        : state.copyWith(mangaInfoSource: service);
  }

  Future<void> setDescriptionSource(
    MediaType type,
    ServiceType? service,
  ) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setDefaultDescriptionSource(type, service);
    state = type == MediaType.anime
        ? state.copyWith(animeDescriptionSource: () => service)
        : state.copyWith(mangaDescriptionSource: () => service);
  }

  Future<void> setSyncSource(MediaType type, ServiceType service) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setDefaultSyncSource(type, service);
    state = type == MediaType.anime
        ? state.copyWith(animeSyncSource: service)
        : state.copyWith(mangaSyncSource: service);
  }
}

final dataSourceSettingsProvider =
    NotifierProvider<DataSourceSettingsNotifier, DataSourceSettings>(
      DataSourceSettingsNotifier.new,
    );
