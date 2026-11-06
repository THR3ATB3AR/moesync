import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_release.dart';
import 'storage_service.dart';

class ReleaseService {
  ReleaseService(this._storage, {http.Client? client})
    : _client = client ?? http.Client();

  static final _releasesUrl = Uri.https(
    'api.github.com',
    '/repos/THR3ATB3AR/moesync/releases',
  );

  final StorageService _storage;
  final http.Client _client;
  List<AppRelease>? _cachedReleases;
  DateTime? _lastAutomaticCheck;

  List<AppRelease>? get cachedReleases => _cachedReleases;
  AppRelease? get latestRelease {
    final releases = _cachedReleases;
    return releases == null
        ? null
        : latestReleaseFor(releases, includeNightly: false);
  }

  AppRelease? get latestUpdateCandidate {
    final releases = _cachedReleases;
    return releases == null
        ? null
        : latestReleaseFor(
            releases,
            includeNightly: _storage.getCheckNightlyUpdates(),
          );
  }

  static AppRelease? latestReleaseFor(
    List<AppRelease> releases, {
    required bool includeNightly,
  }) {
    final candidates = releases.where(
      (release) =>
          !release.isPrerelease || (includeNightly && _isNightly(release)),
    );
    AppRelease? latest;
    for (final release in candidates) {
      if (latest == null ||
          compareVersions(release.tagName, latest.tagName) > 0 ||
          (compareVersions(release.tagName, latest.tagName) == 0 &&
              (release.publishedAt ?? DateTime(0)).isAfter(
                latest.publishedAt ?? DateTime(0),
              ))) {
        latest = release;
      }
    }
    return latest;
  }

  static bool _isNightly(AppRelease release) => RegExp(
    r'(^|[-._])nightly([-.]|$)',
    caseSensitive: false,
  ).hasMatch('${release.tagName} ${release.name}');

  Future<List<AppRelease>> fetchReleases() async {
    final releases = <AppRelease>[];
    var page = 1;
    while (true) {
      final uri = _releasesUrl.replace(
        queryParameters: {'per_page': '100', 'page': '$page'},
      );
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'User-Agent': 'MoeSync',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw HttpException(
          'GitHub Releases request failed (${response.statusCode}).',
          uri: uri,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) {
        throw const FormatException('Invalid GitHub Releases response.');
      }
      releases.addAll(
        decoded.map(
          (release) => AppRelease.fromJson(release as Map<String, dynamic>),
        ),
      );
      if (decoded.length < 100) break;
      page++;
    }

    _cachedReleases = List.unmodifiable(releases);
    return _cachedReleases!;
  }

  Future<AppRelease?> checkAutomatically() async {
    final frequency = _storage.getUpdateCheckFrequency();
    if (frequency == UpdateCheckFrequency.manual) return null;

    final now = DateTime.now();
    final lastCheck = _storage.getLastReleaseCheck();
    if (frequency == UpdateCheckFrequency.daily &&
        lastCheck != null &&
        now.difference(lastCheck) < const Duration(days: 1)) {
      return null;
    }
    if (frequency == UpdateCheckFrequency.onAppOpen &&
        _lastAutomaticCheck != null &&
        now.difference(_lastAutomaticCheck!) < const Duration(seconds: 30)) {
      return null;
    }

    await fetchReleases();
    await _storage.setLastReleaseCheck(now);
    _lastAutomaticCheck = now;
    return latestUpdateCandidate;
  }

  Future<List<AppRelease>> checkManually() async {
    final releases = await fetchReleases();
    await _storage.setLastReleaseCheck(DateTime.now());
    return releases;
  }

  static bool isUpdateAvailable(String currentVersion, AppRelease? release) {
    if (release == null) return false;
    return compareVersions(release.tagName, currentVersion) > 0;
  }

  static int compareVersions(String first, String second) {
    final firstVersion = _parseVersion(first);
    final secondVersion = _parseVersion(second);
    if (firstVersion == null || secondVersion == null) return 0;

    for (var index = 0; index < 3; index++) {
      final comparison = firstVersion.core[index].compareTo(
        secondVersion.core[index],
      );
      if (comparison != 0) return comparison;
    }

    final firstPreRelease = firstVersion.preRelease;
    final secondPreRelease = secondVersion.preRelease;
    if (firstPreRelease.isEmpty || secondPreRelease.isEmpty) {
      if (firstPreRelease.isEmpty == secondPreRelease.isEmpty) return 0;
      return firstPreRelease.isEmpty ? 1 : -1;
    }
    for (
      var index = 0;
      index < firstPreRelease.length && index < secondPreRelease.length;
      index++
    ) {
      final firstPart = firstPreRelease[index];
      final secondPart = secondPreRelease[index];
      final firstNumber = int.tryParse(firstPart);
      final secondNumber = int.tryParse(secondPart);
      final comparison = firstNumber != null && secondNumber != null
          ? firstNumber.compareTo(secondNumber)
          : firstNumber != null
          ? -1
          : secondNumber != null
          ? 1
          : firstPart.compareTo(secondPart);
      if (comparison != 0) return comparison;
    }
    return firstPreRelease.length.compareTo(secondPreRelease.length);
  }

  static _ParsedVersion? _parseVersion(String version) {
    final match = RegExp(
      r'^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
    ).firstMatch(version.trim());
    if (match == null) return null;
    return _ParsedVersion(
      core: [
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      ],
      preRelease: match.group(4)?.split('.') ?? const [],
    );
  }

  void dispose() {
    _client.close();
  }

  @visibleForTesting
  static const githubReleasesEndpoint =
      'https://api.github.com/repos/THR3ATB3AR/moesync/releases';
}

class _ParsedVersion {
  const _ParsedVersion({required this.core, required this.preRelease});

  final List<int> core;
  final List<String> preRelease;
}
