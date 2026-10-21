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

  List<AppRelease>? get cachedReleases => _cachedReleases;
  AppRelease? get latestRelease {
    final releases = _cachedReleases;
    if (releases == null) return null;
    for (final release in releases) {
      if (!release.isPrerelease) return release;
    }
    return releases.isEmpty ? null : releases.first;
  }

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

  Future<void> checkAutomatically() async {
    final frequency = _storage.getUpdateCheckFrequency();
    if (frequency == UpdateCheckFrequency.manual) return;

    final now = DateTime.now();
    final lastCheck = _storage.getLastReleaseCheck();
    if (frequency == UpdateCheckFrequency.daily &&
        lastCheck != null &&
        now.difference(lastCheck) < const Duration(days: 1)) {
      return;
    }
    if (frequency == UpdateCheckFrequency.onAppOpen &&
        lastCheck != null &&
        now.difference(lastCheck) < const Duration(seconds: 30)) {
      return;
    }

    await fetchReleases();
    await _storage.setLastReleaseCheck(now);
  }

  Future<List<AppRelease>> checkManually() async {
    final releases = await fetchReleases();
    await _storage.setLastReleaseCheck(DateTime.now());
    return releases;
  }

  static bool isUpdateAvailable(String currentVersion, AppRelease? release) {
    if (release == null) return false;
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(release.tagName);
    if (current == null || latest == null) return false;
    for (var index = 0; index < current.length; index++) {
      if (latest[index] != current[index]) {
        return latest[index] > current[index];
      }
    }
    return false;
  }

  static List<int>? _parseVersion(String version) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)').firstMatch(version);
    if (match == null) return null;
    return [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ];
  }

  void dispose() {
    _client.close();
  }

  @visibleForTesting
  static const githubReleasesEndpoint =
      'https://api.github.com/repos/THR3ATB3AR/moesync/releases';
}
