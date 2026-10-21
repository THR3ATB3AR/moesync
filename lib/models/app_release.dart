import 'dart:ffi';
import 'dart:io';

enum UpdateCheckFrequency { manual, daily, onAppOpen }

class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.downloadUrl});

  final String name;
  final Uri downloadUrl;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final downloadUrl = json['browser_download_url'];
    if (name is! String || downloadUrl is! String) {
      throw const FormatException('Invalid GitHub release asset.');
    }
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || uri.scheme != 'https') {
      throw const FormatException('Invalid GitHub release asset URL.');
    }
    return ReleaseAsset(name: name, downloadUrl: uri);
  }
}

class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.publishedAt,
    required this.assets,
    required this.isPrerelease,
  });

  final String tagName;
  final String name;
  final String body;
  final Uri htmlUrl;
  final DateTime? publishedAt;
  final List<ReleaseAsset> assets;
  final bool isPrerelease;

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'];
    final htmlUrl = json['html_url'];
    final assetsJson = json['assets'];
    if (tagName is! String ||
        htmlUrl is! String ||
        assetsJson is! List<dynamic>) {
      throw const FormatException('Invalid GitHub release.');
    }
    final parsedUrl = Uri.tryParse(htmlUrl);
    if (parsedUrl == null || parsedUrl.scheme != 'https') {
      throw const FormatException('Invalid GitHub release URL.');
    }
    return AppRelease(
      tagName: tagName,
      name: json['name'] as String? ?? tagName,
      body: json['body'] as String? ?? '',
      htmlUrl: parsedUrl,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      assets: assetsJson
          .map((asset) => ReleaseAsset.fromJson(asset as Map<String, dynamic>))
          .toList(growable: false),
      isPrerelease: json['prerelease'] as bool? ?? false,
    );
  }
}

class ReleaseDownloadTarget {
  const ReleaseDownloadTarget({
    required this.operatingSystem,
    required this.architecture,
  });

  final String operatingSystem;
  final String architecture;

  static ReleaseDownloadTarget? get current {
    final abi = Abi.current();
    if (Platform.isAndroid) {
      final architecture = switch (abi) {
        Abi.androidArm => 'armeabi-v7a',
        Abi.androidArm64 => 'arm64-v8a',
        Abi.androidX64 => 'x86_64',
        Abi.androidIA32 => 'x86',
        _ => null,
      };
      return architecture == null
          ? null
          : ReleaseDownloadTarget(
              operatingSystem: 'android',
              architecture: architecture,
            );
    }
    if (Platform.isWindows && abi == Abi.windowsX64) {
      return const ReleaseDownloadTarget(
        operatingSystem: 'windows',
        architecture: 'x64',
      );
    }
    if (Platform.isLinux && abi == Abi.linuxX64) {
      return const ReleaseDownloadTarget(
        operatingSystem: 'linux',
        architecture: 'x86_64',
      );
    }
    return null;
  }

  ReleaseAsset? selectAsset(List<ReleaseAsset> assets) {
    if (operatingSystem == 'android') {
      final preferred = assets.where(
        (asset) => asset.name.endsWith('-android-$architecture.apk'),
      );
      if (preferred.isNotEmpty) return preferred.first;
      final universal = assets.where(
        (asset) => asset.name.endsWith('-android-universal.apk'),
      );
      return universal.isEmpty ? null : universal.first;
    }

    if (operatingSystem == 'windows' && architecture == 'x64') {
      final setup = assets.where(
        (asset) => asset.name.endsWith('-windows-x64-setup.exe'),
      );
      if (setup.isNotEmpty) return setup.first;
      final archive = assets.where(
        (asset) => asset.name.endsWith('-windows-x64.zip'),
      );
      return archive.isEmpty ? null : archive.first;
    }

    if (operatingSystem == 'linux' && architecture == 'x86_64') {
      final appImage = assets.where(
        (asset) => asset.name.endsWith('-linux-x86_64.AppImage'),
      );
      if (appImage.isNotEmpty) return appImage.first;
      final archive = assets.where(
        (asset) =>
            asset.name.contains('-linux-x64-') &&
            asset.name.endsWith('.tar.gz'),
      );
      return archive.isEmpty ? null : archive.first;
    }

    return null;
  }
}
