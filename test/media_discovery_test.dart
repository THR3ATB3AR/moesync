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
import 'package:moesync/services/storage_service.dart';
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
      expect(items, hasLength(1));
      expect(items.single.malId, 314);
      expect(items.single.releaseSeason, 'FALL');
      expect(items.single.releaseYear, 2026);
    },
  );

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
          mediaDiscoveryProvider(
            query,
          ).overrideWith((ref) async => <MediaItem>[]),
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
}
