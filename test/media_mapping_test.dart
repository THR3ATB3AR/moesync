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
      identity(ServiceType.mal, 102),
      identity(ServiceType.anilist, 303),
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

  test('suggestions group three matching entries into one mapping', () async {
    final items = [
      for (final (service, id, title) in [
        (ServiceType.mal, 101, 'Kamui (TV)'),
        (ServiceType.kitsu, 202, 'Kamui'),
        (ServiceType.anilist, 303, 'Kamui: Special'),
      ])
        UnifiedMediaItem(
          malId: id,
          title: title,
          mediaType: MediaType.anime,
          services: {
            service: MediaItem(
              id: id,
              title: title,
              alternativeTitles: const ['Kamui Shared'],
              status: 'watching',
              score: 0,
              progress: 0,
              posterImage: '',
              service: service,
            ),
          },
        ),
    ];

    final suggestions = findSuggestedMediaMappings(items);

    expect(suggestions, hasLength(1));
    expect(suggestions.single.items, hasLength(3));
    expect(suggestions.single.key, contains('anilist:303'));
    await storage.saveManualMediaMapping([
      for (final item in suggestions.single.items)
        for (final serviceItem in item.services.values)
          MediaMappingIdentity.fromItem(serviceItem),
    ]);
    expect(storage.getManualMediaMappings().single.members, hasLength(3));
  });
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
