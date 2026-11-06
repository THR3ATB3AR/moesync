import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moesync/l10n/gen/app_localizations.dart';
import 'package:moesync/models/media_discovery.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/providers/providers.dart';
import 'package:moesync/screens/media_discovery_screen.dart';
import 'package:moesync/services/anilist_rate_limiter.dart';
import 'package:moesync/services/anilist_service.dart';
import 'package:moesync/services/kitsu_service.dart';
import 'package:moesync/services/manga_mapping_service.dart';
import 'package:moesync/services/mangabaka_service.dart';
import 'package:moesync/services/storage_service.dart';
import 'package:moesync/widgets/service_badge.dart';
import 'package:moesync/widgets/home/home_widget_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    AnilistRateLimiter.resetState();
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
  });

  tearDown(AnilistRateLimiter.resetState);

  test('season calculation crosses year boundaries', () {
    expect(AnimeSeason.forDate(DateTime(2026, 10, 1)), AnimeSeason.fall);
    expect(AnimeSeason.forDate(DateTime(2027, 1, 1)), AnimeSeason.winter);
    expect(AnimeSeason.fall.next, AnimeSeason.winter);
    expect(AnimeSeason.winter.previous, AnimeSeason.fall);
  });

  test('discovery entries merge by MAL ID or matching titles', () {
    final anime = _discoveryItem(
      service: ServiceType.anilist,
      id: 21,
      malId: 99,
      title: 'Shared anime',
    );
    final mal = _discoveryItem(
      service: ServiceType.mal,
      id: 99,
      title: 'Shared anime',
      score: 8,
    );
    final manga = _discoveryItem(
      service: ServiceType.kitsu,
      id: 45,
      title: 'Shared manga',
      mediaType: MediaType.manga,
    );
    final shikimori = _discoveryItem(
      service: ServiceType.shikimori,
      id: 46,
      title: 'Shared manga',
      mediaType: MediaType.manga,
      score: 9,
    );

    final unified = unifyDiscoveryItems([anime, mal, manga, shikimori]);

    expect(unified, hasLength(2));
    expect(
      unified.first.services.keys,
      containsAll([ServiceType.anilist, ServiceType.mal]),
    );
    expect(unified.first.malScore, 8);
    expect(
      unified.last.services.keys,
      containsAll([ServiceType.kitsu, ServiceType.shikimori]),
    );
  });

  test('discovery entries with different titles merge by mapped MAL ID', () {
    final anilist = _discoveryItem(
      service: ServiceType.anilist,
      id: 21,
      malId: 99,
      title: 'Alternative romanized title',
    );
    final kitsu = _discoveryItem(
      service: ServiceType.kitsu,
      id: 45,
      malId: 99,
      title: 'Japanese title',
    );

    final unified = unifyDiscoveryItems([anilist, kitsu]);

    expect(unified, hasLength(1));
    expect(
      unified.single.services.keys,
      containsAll([ServiceType.anilist, ServiceType.kitsu]),
    );
  });

  test('cached manga mappings return available services', () async {
    await storage.saveMangaMappingCache(
      jsonEncode([
        {
          'mal': 99,
          'anilist': 21,
          'kitsu': 45,
          'mangabaka': 78,
          'mangaupdates': 56,
        },
      ]),
    );
    final mapping = MangaMappingService(storage, MangaBakaService(storage));

    await mapping.initialize();

    expect(
      mapping.findMappedServices(99),
      containsAll([
        ServiceType.mal,
        ServiceType.anilist,
        ServiceType.kitsu,
        ServiceType.mangabaka,
        ServiceType.mangaupdates,
      ]),
    );
    expect(mapping.findMappedServices(100), isEmpty);
  });

  testWidgets('discovery card shows services from cached manga mappings', (
    tester,
  ) async {
    await storage.saveMangaMappingCache(
      jsonEncode([
        {
          'mal': 99,
          'anilist': 21,
          'kitsu': 45,
          'mangabaka': 78,
          'mangaupdates': 56,
        },
      ]),
    );
    final mapping = MangaMappingService(storage, MangaBakaService(storage));
    await mapping.initialize();
    final item = unifyDiscoveryItems([
      _discoveryItem(
        service: ServiceType.kitsu,
        id: 45,
        malId: 99,
        title: 'Cached manga',
        mediaType: MediaType.manga,
      ),
    ]).single;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          mediaLibraryProvider.overrideWith(
            () => _TestMediaLibraryNotifier([]),
          ),
          mangaMappingServiceProvider.overrideWithValue(mapping),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 320,
              child: MediaDiscoveryCard(item: item, type: MediaType.manga),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ServiceBadgeChip), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  test(
    'AniList discovery requests the selected season and parses results',
    () async {
      late Map<String, dynamic> request;
      AnilistRateLimiter.testClient = MockClient((httpRequest) async {
        request = jsonDecode(httpRequest.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'data': {
              'Page': {
                'media': [
                  {
                    'id': 42,
                    'idMal': 314,
                    'title': {
                      'userPreferred': 'Example anime',
                      'english': 'Example anime',
                      'native': 'Example',
                      'romaji': 'Rei',
                    },
                    'episodes': 12,
                    'format': 'TV',
                    'season': 'FALL',
                    'seasonYear': 2026,
                    'coverImage': {'large': 'https://example.test/poster.jpg'},
                  },
                ],
              },
            },
          }),
          200,
        );
      });

      final service = AnilistService(storage);
      final items = await service.discover(
        const MediaDiscoveryQuery(
          category: MediaDiscoveryCategory.currentSeason,
          season: AnimeSeason.fall,
          year: 2026,
          includeOtherServices: true,
        ),
      );

      expect(request['variables']['season'], 'FALL');
      expect(request['variables']['seasonYear'], 2026);
      expect(request['variables']['page'], 1);
      expect(items, hasLength(1));
      expect(items.single.malId, 314);
      expect(items.single.releaseSeason, 'FALL');
      expect(items.single.releaseYear, 2026);

      await service.discover(
        const MediaDiscoveryQuery(
          category: MediaDiscoveryCategory.currentSeason,
          season: AnimeSeason.fall,
          year: 2026,
        ),
        pageNumber: 2,
      );
      expect(request['variables']['page'], 2);
    },
  );

  test(
    'Kitsu discovery parses MAL mappings and requests later pages',
    () async {
      late Uri requestUri;
      final service = KitsuService(
        storage,
        client: MockClient((request) async {
          requestUri = request.url;
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'kitsu-45',
                  'attributes': {
                    'canonicalTitle': 'Shared title',
                    'titles': {'en': 'Shared title'},
                    'posterImage': {},
                  },
                  'relationships': {
                    'mappings': {
                      'data': [
                        {'type': 'mappings', 'id': 'mapping-1'},
                      ],
                    },
                  },
                },
              ],
              'included': [
                {
                  'type': 'mappings',
                  'id': 'mapping-1',
                  'attributes': {
                    'externalSite': 'myanimelist/anime',
                    'externalId': '99',
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final items = await service.discover(
        const MediaDiscoveryQuery(category: MediaDiscoveryCategory.trending),
        pageNumber: 2,
      );

      expect(requestUri.queryParameters['page[offset]'], '30');
      expect(items.single.malId, 99);
    },
  );

  testWidgets('discovery grid requests the next page while scrolling', (
    tester,
  ) async {
    const query = MediaDiscoveryQuery(
      category: MediaDiscoveryCategory.trending,
      includeOtherServices: true,
    );
    final firstPageItems = List.generate(
      mediaDiscoveryPageSize,
      (index) => _discoveryItem(
        service: ServiceType.anilist,
        id: index + 1,
        malId: index + 100,
        title: 'Page one item $index',
      ),
    );
    var requestedSecondPage = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          mediaLibraryProvider.overrideWith(
            () => _TestMediaLibraryNotifier([]),
          ),
          mediaDiscoveryPageProvider(
            const MediaDiscoveryPageRequest(query: query, page: 1),
          ).overrideWith(
            (ref) async =>
                MediaDiscoveryPage(items: firstPageItems, hasMore: true),
          ),
          mediaDiscoveryPageProvider(
            const MediaDiscoveryPageRequest(query: query, page: 2),
          ).overrideWith((ref) async {
            requestedSecondPage = true;
            return const MediaDiscoveryPage(items: [], hasMore: false);
          }),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaDiscoveryScreen(initialQuery: query),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GridView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(requestedSecondPage, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('season grid exposes season and year filters', (tester) async {
    const query = MediaDiscoveryQuery(
      category: MediaDiscoveryCategory.currentSeason,
      season: AnimeSeason.fall,
      year: 2026,
      includeOtherServices: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          mediaDiscoveryPageProvider(
            MediaDiscoveryPageRequest(query: query, page: 1),
          ).overrideWith(
            (ref) async =>
                const MediaDiscoveryPage(items: <MediaItem>[], hasMore: false),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaDiscoveryScreen(initialQuery: query),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Season and year'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery card shows personal status, rating, and services', (
    tester,
  ) async {
    final catalogItem = _discoveryItem(
      service: ServiceType.anilist,
      id: 21,
      malId: 99,
      title: 'Shared anime',
    );
    final extraService = _discoveryItem(
      service: ServiceType.mal,
      id: 99,
      title: 'Shared anime',
      score: 8,
    );
    final userListItem = _discoveryItem(
      service: ServiceType.anilist,
      id: 21,
      malId: 99,
      title: 'Shared anime',
      status: 'watching',
      mediaType: MediaType.anime,
    );
    final catalogEntry = unifyDiscoveryItems([
      catalogItem,
      extraService,
    ]).single;
    final userEntry = unifyDiscoveryItems([userListItem]).single;
    final libraryNotifier = _TestMediaLibraryNotifier([userEntry]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          mediaLibraryProvider.overrideWith(() => libraryNotifier),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: MediaDiscoveryCard(
                item: catalogEntry,
                type: MediaType.anime,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shared anime'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    expect(find.byType(ServiceBadgeChip), findsNWidgets(2));
    expect(find.textContaining('Episode'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('empty-library'),
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          mediaLibraryProvider.overrideWith(
            () => _TestMediaLibraryNotifier([]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: MediaDiscoveryCard(
                item: catalogEntry,
                type: MediaType.anime,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsNothing);
    expect(find.byIcon(Icons.bookmark_add_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

MediaItem _discoveryItem({
  required ServiceType service,
  required int id,
  required String title,
  int? malId,
  int score = 0,
  String status = 'plan_to_watch',
  MediaType mediaType = MediaType.anime,
}) => MediaItem(
  id: id,
  malId: malId,
  title: title,
  status: status,
  score: score,
  progress: 0,
  posterImage: '',
  service: service,
  mediaType: mediaType,
);

class _TestMediaLibraryNotifier extends MediaLibraryNotifier {
  _TestMediaLibraryNotifier(this.items);

  final List<UnifiedMediaItem> items;

  @override
  MediaLibraryState build() => MediaLibraryState(unifiedItems: items);
}
