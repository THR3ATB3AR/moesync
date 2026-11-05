import 'package:flutter_test/flutter_test.dart';
import 'package:moesync/models/media_item.dart';
import 'package:moesync/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
  });

  test(
    'search results are cached as JSON per media type and normalized query',
    () async {
      final anime = MediaItem(
        id: 100,
        malId: 10,
        title: 'Cached Anime',
        status: 'plan_to_watch',
        score: 0,
        progress: 0,
        posterImage: 'https://example.com/anime.jpg',
        service: ServiceType.anilist,
        mediaType: MediaType.anime,
      );
      final manga = MediaItem(
        id: 200,
        malId: 20,
        title: 'Cached Manga',
        status: 'plan_to_read',
        score: 0,
        progress: 0,
        posterImage: 'https://example.com/manga.jpg',
        service: ServiceType.anilist,
        mediaType: MediaType.manga,
      );

      await storage.saveCachedSearchResults('  My   Query ', MediaType.anime, [
        anime,
      ]);
      await storage.saveCachedSearchResults('my query', MediaType.manga, [
        manga,
      ]);

      expect(
        storage
            .getCachedSearchResults('MY query', MediaType.anime)
            ?.single
            .title,
        'Cached Anime',
      );
      expect(
        storage
            .getCachedSearchResults('my query', MediaType.manga)
            ?.single
            .title,
        'Cached Manga',
      );
      expect(
        storage.getCachedSearchResults('my query', MediaType.anime)?.single.id,
        anime.id,
      );
    },
  );

  test(
    'search history moves repeated searches to the front and can be cleared',
    () async {
      await storage.saveMediaSearchHistory('Naruto', MediaType.anime);
      await storage.saveMediaSearchHistory('Berserk', MediaType.manga);
      await storage.saveMediaSearchHistory('naruto', MediaType.anime);

      expect(storage.getMediaSearchHistory(), [
        (query: 'naruto', mediaType: MediaType.anime),
        (query: 'Berserk', mediaType: MediaType.manga),
      ]);

      await storage.clearMediaSearchHistory();
      expect(storage.getMediaSearchHistory(), isEmpty);
    },
  );
}
