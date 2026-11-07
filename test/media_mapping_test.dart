import 'package:flutter_test/flutter_test.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/models/media_mapping.dart';
import 'package:moesync/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
  });

  MediaMappingIdentity identity(
    ServiceType service,
    int id, {
    MediaType type = MediaType.anime,
  }) => MediaMappingIdentity(mediaType: type, service: service, id: id);

  test('manual mappings persist and merge overlapping groups', () async {
    final mal = identity(ServiceType.mal, 101);
    final kitsu = identity(ServiceType.kitsu, 202);
    final anilist = identity(ServiceType.anilist, 303);

    await storage.saveManualMediaMapping([mal, kitsu]);
    await storage.saveManualMediaMapping([kitsu, anilist]);

    final mappings = storage.getManualMediaMappings();
    expect(mappings, hasLength(1));
    expect(mappings.single.members.map((member) => member.key).toSet(), {
      mal.key,
      kitsu.key,
      anilist.key,
    });

    final index = ManualMediaMappingIndex(mappings, MediaType.anime);
    expect(
      index.groupKeyFor(
        _mediaItem(service: ServiceType.kitsu, id: 202, type: MediaType.anime),
      ),
      index.groupKeyFor(
        _mediaItem(service: ServiceType.mal, id: 101, type: MediaType.anime),
      ),
    );
    expect(
      index.malIdFor(
        _mediaItem(service: ServiceType.kitsu, id: 202, type: MediaType.anime),
      ),
      101,
    );
    expect(
      index.groupKeyFor(
        _mediaItem(
          service: ServiceType.anilist,
          id: 303,
          type: MediaType.manga,
        ),
      ),
      isNull,
    );
  });

  test('separate mappings stay separate when saved in a batch', () async {
    await storage.saveManualMediaMapping([
      identity(ServiceType.mal, 101),
      identity(ServiceType.kitsu, 202),
    ]);
    await storage.saveManualMediaMapping([
      identity(ServiceType.anilist, 303),
      identity(ServiceType.shikimori, 404),
    ]);

    final mappings = storage.getManualMediaMappings();
    expect(mappings, hasLength(2));
    expect(mappings.map((mapping) => mapping.members.length), everyElement(2));
  });

  test('manual mappings can be removed and cannot mix media types', () async {
    final mal = identity(ServiceType.mal, 101);
    final kitsu = identity(ServiceType.kitsu, 202);
    await storage.saveManualMediaMapping([mal, kitsu]);

    await storage.removeManualMediaMapping(
      storage.getManualMediaMappings().single,
    );
    expect(storage.getManualMediaMappings(), isEmpty);

    await expectLater(
      storage.saveManualMediaMapping([
        mal,
        identity(ServiceType.mangabaka, 303, type: MediaType.manga),
      ]),
      throwsArgumentError,
    );
  });

  test(
    'unified identity recognizes mapped source IDs but separates media types',
    () {
      final anime = UnifiedMediaItem(
        malId: -1,
        title: 'Kamui',
        mediaType: MediaType.anime,
        services: {
          ServiceType.kitsu: _mediaItem(
            service: ServiceType.kitsu,
            id: 202,
            type: MediaType.anime,
          ),
        },
      );
      final sameAnime = UnifiedMediaItem(
        malId: -2,
        title: 'Kamui (TV)',
        mediaType: MediaType.anime,
        services: {
          ServiceType.kitsu: _mediaItem(
            service: ServiceType.kitsu,
            id: 202,
            type: MediaType.anime,
          ),
        },
      );
      final manga = UnifiedMediaItem(
        malId: -1,
        title: 'Kamui',
        mediaType: MediaType.manga,
        services: {
          ServiceType.kitsu: _mediaItem(
            service: ServiceType.kitsu,
            id: 202,
            type: MediaType.manga,
          ),
        },
      );

      expect(sameUnifiedMediaItem(anime, sameAnime), isTrue);
      expect(sameUnifiedMediaItem(anime, manga), isFalse);
    },
  );
}

MediaItem _mediaItem({
  required ServiceType service,
  required int id,
  required MediaType type,
}) => MediaItem(
  id: id,
  title: 'Mapped title',
  status: type == MediaType.anime ? 'watching' : 'reading',
  score: 0,
  progress: 0,
  posterImage: '',
  service: service,
  mediaType: type,
);
