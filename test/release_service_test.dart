import 'package:flutter_test/flutter_test.dart';
import 'package:moesync/models/app_release.dart';
import 'package:moesync/services/release_service.dart';
import 'package:moesync/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
  });

  test('nightly update checks are opt-in and persist', () async {
    expect(storage.getCheckNightlyUpdates(), isFalse);

    await storage.setCheckNightlyUpdates(true);
    expect(storage.getCheckNightlyUpdates(), isTrue);
  });

  test('nightly releases are selected only when enabled', () {
    final releases = [
      _release('v1.0.0', isPrerelease: false),
      _release('v1.0.1-nightly.20261105.10', isPrerelease: true),
      _release('v1.0.2-beta.1', isPrerelease: true),
    ];

    expect(
      ReleaseService.latestReleaseFor(releases, includeNightly: false)?.tagName,
      'v1.0.0',
    );
    expect(
      ReleaseService.latestReleaseFor(releases, includeNightly: true)?.tagName,
      'v1.0.1-nightly.20261105.10',
    );
    expect(
      ReleaseService.latestReleaseFor([
        _release('v1.0.1', isPrerelease: false),
        _release('v1.0.1-nightly.20261106.11', isPrerelease: true),
      ], includeNightly: true)?.tagName,
      'v1.0.1',
    );
  });

  test('nightly versions are compared by prerelease sequence', () {
    final earlier = _release('v1.0.1-nightly.20261105.10', isPrerelease: true);
    final later = _release('v1.0.1-nightly.20261106.11', isPrerelease: true);
    final stable = _release('v1.0.1', isPrerelease: false);

    expect(ReleaseService.isUpdateAvailable('1.0.0+10', earlier), isTrue);
    expect(
      ReleaseService.isUpdateAvailable('1.0.1-nightly.20261105.10+10', later),
      isTrue,
    );
    expect(
      ReleaseService.isUpdateAvailable('1.0.1-nightly.20261106.11+11', stable),
      isTrue,
    );
    expect(ReleaseService.isUpdateAvailable('1.0.1+12', earlier), isFalse);
  });
}

AppRelease _release(String tag, {required bool isPrerelease}) => AppRelease(
  tagName: tag,
  name: isPrerelease ? 'MoeSync Nightly $tag' : 'MoeSync $tag',
  body: '',
  htmlUrl: Uri.parse('https://github.com/THR3ATB3AR/moesync/releases/$tag'),
  publishedAt: DateTime.utc(2026, 11, 6),
  assets: const [],
  isPrerelease: isPrerelease,
);
