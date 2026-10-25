import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/anime_api_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_release.dart';
import '../models/media_item.dart';
import 'env.dart';

class StorageService {
  static const _credentialsKeyPrefix = 'service_credentials_';
  static const _animeApiDatabaseMetadataKey = 'animeapi_database_metadata';
  static const _cachedUnifiedAnimeKey = 'cached_unified_anime';
  static const _cachedUnifiedMangaKey = 'cached_unified_manga';
  static const _mangaMappingCacheKey = 'manga_mapping_cache';

  static String get defaultMalClientId => Env.malClientId;
  static String get defaultMalClientSecret => Env.malClientSecret;
  static String get defaultAnilistClientId => Env.anilistClientId;
  static String get defaultAnilistClientSecret => Env.anilistClientSecret;
  static String get defaultShikimoriClientId => Env.shikimoriClientId;
  static String get defaultShikimoriClientSecret => Env.shikimoriClientSecret;
  static String get defaultSimklClientId => Env.simklClientId;
  static String get defaultSimklClientSecret => Env.simklClientSecret;
  static String get defaultMangaBakaClientId => Env.mangaBakaClientId;

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  final _credentialsListeners =
      <void Function(ServiceType, ServiceCredentials)>[];

  void addCredentialsListener(
    void Function(ServiceType, ServiceCredentials) listener,
  ) {
    _credentialsListeners.add(listener);
  }

  void removeCredentialsListener(
    void Function(ServiceType, ServiceCredentials) listener,
  ) {
    _credentialsListeners.remove(listener);
  }

  Future<void> saveCredentials(
    ServiceType service,
    ServiceCredentials credentials,
  ) async {
    final key = '$_credentialsKeyPrefix${service.name}';
    final jsonStr = jsonEncode(credentials.toJson());
    await _prefs.setString(key, jsonStr);
    await _prefs.remove('disconnected_${service.name}');
    for (final l in List.from(_credentialsListeners)) {
      l(service, credentials);
    }
  }

  ServiceCredentials getCredentials(ServiceType service) {
    final key = '$_credentialsKeyPrefix${service.name}';
    final jsonStr = _prefs.getString(key);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final creds = ServiceCredentials.fromJson(map);
        final def = _defaultCredentials(service);
        return creds.copyWith(
          clientId: creds.clientId?.isNotEmpty == true
              ? creds.clientId
              : def.clientId,
          clientSecret: creds.clientSecret?.isNotEmpty == true
              ? creds.clientSecret
              : def.clientSecret,
        );
      } catch (_) {}
    }

    return _defaultCredentials(service);
  }

  ServiceCredentials _defaultCredentials(ServiceType service) {
    switch (service) {
      case ServiceType.mal:
        return ServiceCredentials(
          clientId: defaultMalClientId.isNotEmpty ? defaultMalClientId : null,
          clientSecret: defaultMalClientSecret.isNotEmpty
              ? defaultMalClientSecret
              : null,
        );
      case ServiceType.anilist:
        return ServiceCredentials(
          clientId: defaultAnilistClientId.isNotEmpty
              ? defaultAnilistClientId
              : null,
          clientSecret: defaultAnilistClientSecret.isNotEmpty
              ? defaultAnilistClientSecret
              : null,
        );
      case ServiceType.kitsu:
        return const ServiceCredentials();
      case ServiceType.shikimori:
        return ServiceCredentials(
          clientId: defaultShikimoriClientId.isNotEmpty
              ? defaultShikimoriClientId
              : null,
          clientSecret: defaultShikimoriClientSecret.isNotEmpty
              ? defaultShikimoriClientSecret
              : null,
        );
      case ServiceType.simkl:
        return ServiceCredentials(
          clientId: defaultSimklClientId.isNotEmpty
              ? defaultSimklClientId
              : null,
          clientSecret: defaultSimklClientSecret.isNotEmpty
              ? defaultSimklClientSecret
              : null,
        );
      case ServiceType.mangabaka:
        return ServiceCredentials(
          clientId: defaultMangaBakaClientId.isNotEmpty
              ? defaultMangaBakaClientId
              : null,
        );
      case ServiceType.mangaupdates:
        return const ServiceCredentials();
    }
  }

  Future<void> clearCredentials(ServiceType service) async {
    final key = '$_credentialsKeyPrefix${service.name}';
    final def = _defaultCredentials(service);
    await _prefs.setString(key, jsonEncode(def.toJson()));
    await _prefs.setBool('disconnected_${service.name}', true);

    for (final l in List.from(_credentialsListeners)) {
      l(service, def);
    }
  }

  Future<void> clearAllCredentials() async {
    for (final service in ServiceType.values) {
      await clearCredentials(service);
    }
  }

  Future<void> saveAnimeApiDatabaseMetadata(
    AnimeApiDatabaseMetadata metadata,
  ) async {
    await _prefs.setString(
      _animeApiDatabaseMetadataKey,
      jsonEncode(metadata.toJson()),
    );
  }

  AnimeApiDatabaseMetadata? getAnimeApiDatabaseMetadata() {
    final encoded = _prefs.getString(_animeApiDatabaseMetadataKey);
    if (encoded == null) return null;
    try {
      return AnimeApiDatabaseMetadata.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
    } catch (error) {
      debugPrint('Failed to load AnimeApi database metadata: $error');
      return null;
    }
  }

  Future<void> removeLegacyFribbCache() async {
    await _prefs.remove('fribb_mapping_cache');
    await _prefs.remove('fribb_cache_timestamp');
  }

  Future<void> saveMangaMappingCache(String jsonContent) async {
    await _prefs.setString(_mangaMappingCacheKey, jsonContent);
  }

  String? getMangaMappingCache() {
    return _prefs.getString(_mangaMappingCacheKey);
  }

  Future<void> saveCachedItems(
    MediaType type,
    List<Map<String, dynamic>> items,
  ) async {
    final key = type == MediaType.anime
        ? _cachedUnifiedAnimeKey
        : _cachedUnifiedMangaKey;
    await _prefs.setString(key, jsonEncode(items));
  }

  List<Map<String, dynamic>>? getCachedItems(MediaType type) {
    final key = type == MediaType.anime
        ? _cachedUnifiedAnimeKey
        : _cachedUnifiedMangaKey;
    final str = _prefs.getString(key);
    if (str == null) return null;
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  static const _serviceDisplayStyleKey = 'service_display_style';
  static const _mediaViewModeKey = 'media_view_mode';
  static const _appLanguageKey = 'app_language';
  static const _titleLanguageKey = 'title_language';
  static const _updateCheckFrequencyKey = 'update_check_frequency';
  static const _lastReleaseCheckKey = 'last_release_check';

  UpdateCheckFrequency getUpdateCheckFrequency() {
    final value = _prefs.getString(_updateCheckFrequencyKey);
    return UpdateCheckFrequency.values.firstWhere(
      (frequency) => frequency.name == value,
      orElse: () => UpdateCheckFrequency.onAppOpen,
    );
  }

  Future<void> setUpdateCheckFrequency(UpdateCheckFrequency frequency) async {
    await _prefs.setString(_updateCheckFrequencyKey, frequency.name);
  }

  DateTime? getLastReleaseCheck() {
    final timestamp = _prefs.getInt(_lastReleaseCheckKey);
    return timestamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setLastReleaseCheck(DateTime checkedAt) async {
    await _prefs.setInt(_lastReleaseCheckKey, checkedAt.millisecondsSinceEpoch);
  }

  String? getAppLanguage() {
    final language = _prefs.getString(_appLanguageKey);
    return const {'en', 'pl', 'es'}.contains(language) ? language : null;
  }

  Future<void> setAppLanguage(String? language) async {
    if (language != null && !const {'en', 'pl', 'es'}.contains(language)) {
      throw ArgumentError.value(language, 'language', 'Unsupported language');
    }
    if (language == null) {
      await _prefs.remove(_appLanguageKey);
    } else {
      await _prefs.setString(_appLanguageKey, language);
    }
  }

  TitleLanguage getTitleLanguage() {
    final name = _prefs.getString(_titleLanguageKey);
    return TitleLanguage.values.firstWhere(
      (language) => language.name == name,
      orElse: () => TitleLanguage.source,
    );
  }

  Future<void> setTitleLanguage(TitleLanguage language) async {
    await _prefs.setString(_titleLanguageKey, language.name);
  }

  ServiceDisplayStyle getServiceDisplayStyle() {
    final name = _prefs.getString(_serviceDisplayStyleKey);
    if (name != null) {
      for (final s in ServiceDisplayStyle.values) {
        if (s.name == name) return s;
      }
    }
    return ServiceDisplayStyle.text;
  }

  Future<void> setServiceDisplayStyle(ServiceDisplayStyle style) async {
    await _prefs.setString(_serviceDisplayStyleKey, style.name);
  }

  MediaViewMode getMediaViewMode() {
    final name = _prefs.getString(_mediaViewModeKey);
    if (name != null) {
      for (final m in MediaViewMode.values) {
        if (m.name == name) return m;
      }
    }
    return MediaViewMode.grid;
  }

  Future<void> setMediaViewMode(MediaViewMode mode) async {
    await _prefs.setString(_mediaViewModeKey, mode.name);
  }

  static const _syncOnlyExistingKey = 'sync_only_existing';

  bool getSyncOnlyExisting() {
    return _prefs.getBool(_syncOnlyExistingKey) ?? false;
  }

  Future<void> setSyncOnlyExisting(bool onlyExisting) async {
    await _prefs.setBool(_syncOnlyExistingKey, onlyExisting);
  }

  static const _themeModeKey = 'app_theme_mode';
  static const _useDynamicColorKey = 'app_use_dynamic_color';
  static const _seedColorKey = 'app_theme_seed_color';
  static const _schemeVariantKey = 'app_scheme_variant';

  ThemeMode getThemeMode() {
    final val = _prefs.getString(_themeModeKey);
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  bool getUseDynamicColor() {
    return _prefs.getBool(_useDynamicColorKey) ?? true;
  }

  Future<void> setUseDynamicColor(bool use) async {
    await _prefs.setBool(_useDynamicColorKey, use);
  }

  Color getSeedColor() {
    final val = _prefs.getInt(_seedColorKey);
    if (val != null) return Color(val);
    return const Color(0xFF6750A4);
  }

  Future<void> setSeedColor(Color color) async {
    await _prefs.setInt(_seedColorKey, color.toARGB32());
  }

  DynamicSchemeVariant getSchemeVariant() {
    final val = _prefs.getString(_schemeVariantKey);
    if (val != null) {
      for (final v in DynamicSchemeVariant.values) {
        if (v.name == val) return v;
      }
    }
    return DynamicSchemeVariant.tonalSpot;
  }

  Future<void> setSchemeVariant(DynamicSchemeVariant variant) async {
    await _prefs.setString(_schemeVariantKey, variant.name);
  }

  static const _mangaUpdatesPosterCacheKey = 'mangaupdates_posters_cache';

  Map<int, String> getMangaUpdatesPostersCache() {
    final str = _prefs.getString(_mangaUpdatesPosterCacheKey);
    if (str == null || str.isEmpty) return {};
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      final result = <int, String>{};
      map.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && id > 0 && v is String && v.isNotEmpty) {
          result[id] = v;
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveMangaUpdatesPostersCache(Map<int, String> cache) async {
    final map = cache.map((k, v) => MapEntry(k.toString(), v));
    await _prefs.setString(_mangaUpdatesPosterCacheKey, jsonEncode(map));
  }

  Future<void> saveSingleMangaUpdatesPoster(
    int seriesId,
    String posterUrl,
  ) async {
    if (seriesId <= 0 || posterUrl.isEmpty) return;
    final current = getMangaUpdatesPostersCache();
    current[seriesId] = posterUrl;
    await saveMangaUpdatesPostersCache(current);
  }

  static const _animeInfoSourceKey = 'anime_default_info_source';
  static const _mangaInfoSourceKey = 'manga_default_info_source';
  static const _animeDescSourceKey = 'anime_default_desc_source';
  static const _mangaDescSourceKey = 'manga_default_desc_source';
  static const _animeSyncSourceKey = 'anime_default_sync_source';
  static const _mangaSyncSourceKey = 'manga_default_sync_source';

  ServiceType getDefaultInfoSource(MediaType type) {
    final key = type == MediaType.anime
        ? _animeInfoSourceKey
        : _mangaInfoSourceKey;
    final val = _prefs.getString(key);
    if (val != null) {
      for (final s in ServiceType.forMediaType(type)) {
        if (s.name == val) return s;
      }
    }
    return ServiceType.mal;
  }

  Future<void> setDefaultInfoSource(MediaType type, ServiceType service) async {
    final key = type == MediaType.anime
        ? _animeInfoSourceKey
        : _mangaInfoSourceKey;
    await _prefs.setString(key, service.name);
  }

  ServiceType? getDefaultDescriptionSource(MediaType type) {
    final key = type == MediaType.anime
        ? _animeDescSourceKey
        : _mangaDescSourceKey;
    final val = _prefs.getString(key);
    if (val != null && val.isNotEmpty && val != 'auto') {
      for (final s in ServiceType.forMediaType(type)) {
        if (s.name == val) return s;
      }
    }
    return null;
  }

  Future<void> setDefaultDescriptionSource(
    MediaType type,
    ServiceType? service,
  ) async {
    final key = type == MediaType.anime
        ? _animeDescSourceKey
        : _mangaDescSourceKey;
    if (service == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, service.name);
    }
  }

  ServiceType getDefaultSyncSource(MediaType type) {
    final key = type == MediaType.anime
        ? _animeSyncSourceKey
        : _mangaSyncSourceKey;
    final val = _prefs.getString(key);
    if (val != null) {
      for (final s in ServiceType.forMediaType(type)) {
        if (s.name == val) return s;
      }
    }
    return ServiceType.mal;
  }

  Future<void> setDefaultSyncSource(MediaType type, ServiceType service) async {
    final key = type == MediaType.anime
        ? _animeSyncSourceKey
        : _mangaSyncSourceKey;
    await _prefs.setString(key, service.name);
  }
}
