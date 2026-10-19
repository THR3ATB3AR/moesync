import 'dart:io';
import 'package:flutter/foundation.dart';

class Env {
  static final Map<String, String> _dotenv = {};
  static final Map<String, String> _testOverrides = {};
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;

    try {
      final file = File('.env');
      if (file.existsSync()) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final eqIdx = trimmed.indexOf('=');
          if (eqIdx != -1) {
            final key = trimmed.substring(0, eqIdx).trim();
            final val = trimmed.substring(eqIdx + 1).trim();
            _dotenv[key] = val;
          }
        }
      }
    } catch (_) {}
  }

  @visibleForTesting
  static void setForTesting(String key, String value) {
    _testOverrides[key] = value;
  }
  @visibleForTesting
  static void resetForTesting() {
    _testOverrides.clear();
    _dotenv.clear();
    _initialized = false;
  }

  static String _get(String key) {
    if (_testOverrides.containsKey(key)) {
      return _testOverrides[key]!;
    }

    final compileTime = _getCompileTime(key);
    if (compileTime.isNotEmpty) return compileTime;

    if (!_initialized) init();
    final fileVal = _dotenv[key];
    if (fileVal != null && fileVal.isNotEmpty) return fileVal;

    if (!kIsWeb) {
      try {
        final platVal = Platform.environment[key];
        if (platVal != null && platVal.isNotEmpty) return platVal;
      } catch (_) {}
    }

    return '';
  }

  static String _getCompileTime(String key) {
    switch (key) {
      case 'MAL_CLIENT_ID':
        return const String.fromEnvironment('MAL_CLIENT_ID');
      case 'MAL_CLIENT_SECRET':
        return const String.fromEnvironment('MAL_CLIENT_SECRET');
      case 'ANILIST_CLIENT_ID':
        return const String.fromEnvironment('ANILIST_CLIENT_ID');
      case 'ANILIST_CLIENT_SECRET':
        return const String.fromEnvironment('ANILIST_CLIENT_SECRET');
      case 'SHIKIMORI_CLIENT_ID':
        return const String.fromEnvironment('SHIKIMORI_CLIENT_ID');
      case 'SHIKIMORI_CLIENT_SECRET':
        return const String.fromEnvironment('SHIKIMORI_CLIENT_SECRET');
      case 'SIMKL_CLIENT_ID':
        return const String.fromEnvironment('SIMKL_CLIENT_ID');
      case 'SIMKL_CLIENT_SECRET':
        return const String.fromEnvironment('SIMKL_CLIENT_SECRET');
      case 'MANGABAKA_CLIENT_ID':
        return const String.fromEnvironment('MANGABAKA_CLIENT_ID');
      default:
        return '';
    }
  }

  static String get malClientId => _get('MAL_CLIENT_ID');
  static String get malClientSecret => _get('MAL_CLIENT_SECRET');
  static String get anilistClientId => _get('ANILIST_CLIENT_ID');
  static String get anilistClientSecret => _get('ANILIST_CLIENT_SECRET');
  static String get shikimoriClientId => _get('SHIKIMORI_CLIENT_ID');
  static String get shikimoriClientSecret => _get('SHIKIMORI_CLIENT_SECRET');
  static String get simklClientId => _get('SIMKL_CLIENT_ID');
  static String get simklClientSecret => _get('SIMKL_CLIENT_SECRET');
  static String get mangaBakaClientId => _get('MANGABAKA_CLIENT_ID');
}
