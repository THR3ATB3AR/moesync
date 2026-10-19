import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/media_item.dart';
import 'storage_service.dart';

class OAuthService {
  final StorageService storage;
  final http.Client _client;

  OAuthService(this.storage, {http.Client? client})
    : _client = client ?? http.Client();

  static String generateMalCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String generateSimklCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  static String generateSimklCodeChallenge(String verifier) {
    final hash = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(hash.bytes).replaceAll('=', '');
  }

  static String extractCode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.contains('?code=') ||
        trimmed.contains('&code=')) {
      try {
        final uri = Uri.parse(trimmed);
        if (uri.queryParameters.containsKey('code')) {
          return uri.queryParameters['code']!;
        }
        if (uri.hasFragment) {
          final frag = Uri.splitQueryString(uri.fragment);
          if (frag.containsKey('access_token')) {
            return frag['access_token']!;
          }
          if (frag.containsKey('code')) {
            return frag['code']!;
          }
        }
      } catch (_) {}
    }

    final match = RegExp(r'[?&#]code=([^&#\s]+)').firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!;
    }

    return trimmed;
  }

  Future<bool> openUrlInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  ({String url, String codeVerifier}) prepareMalAuth() {
    final creds = storage.getCredentials(ServiceType.mal);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultMalClientId;
    if (clientId.isEmpty) {
      throw Exception(
        'Brak Client ID dla MyAnimeList. Skonfiguruj MAL_CLIENT_ID w pliku .env.',
      );
    }
    final verifier = generateMalCodeVerifier();

    final url = Uri.https('myanimelist.net', '/v1/oauth2/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'code_challenge': verifier,
      'code_challenge_method': 'plain',
      'state': 'state',
      'redirect_uri': 'http://localhost',
    }).toString();

    return (url: url, codeVerifier: verifier);
  }

  Future<ServiceCredentials> exchangeMalToken({
    required String rawCodeOrUrl,
    required String codeVerifier,
  }) async {
    final code = extractCode(rawCodeOrUrl);
    if (code.isEmpty) {
      throw Exception('Authorization code cannot be empty');
    }

    final creds = storage.getCredentials(ServiceType.mal);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultMalClientId;
    final clientSecret = creds.clientSecret?.isNotEmpty == true
        ? creds.clientSecret!
        : StorageService.defaultMalClientSecret;

    final resp = await http.post(
      Uri.parse('https://myanimelist.net/v1/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': codeVerifier,
        'redirect_uri': 'http://localhost',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to exchange MAL token (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    String? username;
    try {
      final userResp = await http.get(
        Uri.parse('https://api.myanimelist.net/v2/users/@me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (userResp.statusCode == 200) {
        final userData = jsonDecode(userResp.body) as Map<String, dynamic>;
        username = userData['name'] as String?;
      }
    } catch (_) {}

    return creds.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      username: username ?? creds.username,
      isConnected: true,
    );
  }

  Future<ServiceCredentials>? _malRefreshFuture;

  Future<ServiceCredentials> refreshMalToken() async {
    if (_malRefreshFuture != null) {
      return await _malRefreshFuture!;
    }
    final future = _performMalRefresh();
    _malRefreshFuture = future;
    try {
      return await future;
    } finally {
      _malRefreshFuture = null;
    }
  }

  Future<ServiceCredentials> _performMalRefresh() async {
    final creds = storage.getCredentials(ServiceType.mal);
    final refreshToken = creds.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception(
        'No refresh token available for MyAnimeList. Please log in again.',
      );
    }

    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultMalClientId;
    final clientSecret = creds.clientSecret?.isNotEmpty == true
        ? creds.clientSecret!
        : StorageService.defaultMalClientSecret;

    final resp = await http.post(
      Uri.parse('https://myanimelist.net/v1/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (resp.statusCode != 200) {
      if (resp.statusCode == 400 || resp.statusCode == 401) {
        await storage.saveCredentials(
          ServiceType.mal,
          creds.copyWith(accessToken: null, isConnected: false),
        );
      }
      throw Exception(
        'Failed to refresh MAL token (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final newAccessToken = data['access_token'] as String;
    final newRefreshToken = (data['refresh_token'] as String?) ?? refreshToken;
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    final updated = creds.copyWith(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresAt: expiresAt,
      isConnected: true,
    );
    await storage.saveCredentials(ServiceType.mal, updated);
    return updated;
  }

  String prepareAnilistAuth() {
    final creds = storage.getCredentials(ServiceType.anilist);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultAnilistClientId;
    if (clientId.isEmpty) {
      throw Exception(
        'Brak Client ID dla AniList. Skonfiguruj ANILIST_CLIENT_ID w pliku .env.',
      );
    }

    return Uri.https('anilist.co', '/api/v2/oauth/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': 'http://localhost',
    }).toString();
  }

  Future<ServiceCredentials> exchangeAnilistToken({
    required String rawCodeOrUrl,
  }) async {
    final code = extractCode(rawCodeOrUrl);
    if (code.isEmpty) {
      throw Exception('Authorization code cannot be empty');
    }

    final creds = storage.getCredentials(ServiceType.anilist);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultAnilistClientId;
    final clientSecret = creds.clientSecret?.isNotEmpty == true
        ? creds.clientSecret!
        : StorageService.defaultAnilistClientSecret;

    String accessToken = '';
    String? refreshToken;

    if (code.startsWith('ey')) {
      accessToken = code;
    } else {
      final resp = await http.post(
        Uri.parse('https://anilist.co/api/v2/oauth/token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'AniSync/1.0.0',
        },
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': 'http://localhost',
          'code': code,
        }),
      );

      if (resp.statusCode != 200) {
        throw Exception(
          'Failed to exchange AniList token (${resp.statusCode}): ${resp.body}',
        );
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      accessToken = data['access_token'] as String;
      refreshToken = data['refresh_token'] as String?;
    }

    String? username;
    String? userId;
    try {
      final userResp = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'AniSync/1.0.0',
        },
        body: jsonEncode({'query': 'query { Viewer { id name } }'}),
      );
      if (userResp.statusCode == 200) {
        final userData = jsonDecode(userResp.body) as Map<String, dynamic>;
        final viewer = userData['data']?['Viewer'] as Map<String, dynamic>?;
        if (viewer != null) {
          username = viewer['name'] as String?;
          userId = viewer['id']?.toString();
        }
      }
    } catch (_) {}

    return creds.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      username: username ?? creds.username,
      userId: userId ?? creds.userId,
      isConnected: true,
    );
  }

  String prepareShikimoriAuth() {
    final creds = storage.getCredentials(ServiceType.shikimori);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultShikimoriClientId;
    if (clientId.isEmpty) {
      throw Exception(
        'Brak Client ID dla Shikimori. Skonfiguruj SHIKIMORI_CLIENT_ID w pliku .env.',
      );
    }

    return Uri.https('shikimori.io', '/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
      'response_type': 'code',
      'scope': '',
    }).toString();
  }

  Future<ServiceCredentials> exchangeShikimoriToken({
    required String rawCodeOrUrl,
  }) async {
    final code = extractCode(rawCodeOrUrl);
    if (code.isEmpty) {
      throw Exception('Authorization code cannot be empty');
    }

    final creds = storage.getCredentials(ServiceType.shikimori);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultShikimoriClientId;
    final clientSecret = creds.clientSecret?.isNotEmpty == true
        ? creds.clientSecret!
        : StorageService.defaultShikimoriClientSecret;

    final resp = await http.post(
      Uri.parse('https://shikimori.io/oauth/token'),
      headers: {
        'User-Agent': 'AniSync',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to exchange Shikimori token (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : DateTime.now().add(const Duration(days: 1));

    String? username;
    String? userId;
    try {
      final userResp = await http.get(
        Uri.parse('https://shikimori.io/api/users/whoami'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'AniSync',
        },
      );
      if (userResp.statusCode == 200) {
        final userData = jsonDecode(userResp.body) as Map<String, dynamic>;
        username = userData['nickname'] as String?;
        userId = (userData['id'] as num?)?.toString();
      }
    } catch (_) {}

    return creds.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      username: username ?? creds.username,
      userId: userId ?? creds.userId,
      isConnected: true,
    );
  }

  Future<ServiceCredentials>? _shikimoriRefreshFuture;

  Future<ServiceCredentials> refreshShikimoriToken() async {
    if (_shikimoriRefreshFuture != null) {
      return await _shikimoriRefreshFuture!;
    }
    final future = _performShikimoriRefresh();
    _shikimoriRefreshFuture = future;
    try {
      return await future;
    } finally {
      _shikimoriRefreshFuture = null;
    }
  }

  Future<ServiceCredentials> _performShikimoriRefresh() async {
    final creds = storage.getCredentials(ServiceType.shikimori);
    final refreshToken = creds.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception(
        'No refresh token available for Shikimori. Please log in again.',
      );
    }

    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultShikimoriClientId;
    final clientSecret = creds.clientSecret?.isNotEmpty == true
        ? creds.clientSecret!
        : StorageService.defaultShikimoriClientSecret;

    final resp = await http.post(
      Uri.parse('https://shikimori.io/oauth/token'),
      headers: {
        'User-Agent': 'AniSync',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': refreshToken,
      },
    );

    if (resp.statusCode != 200) {
      if (resp.statusCode == 400 || resp.statusCode == 401) {
        await storage.saveCredentials(
          ServiceType.shikimori,
          creds.copyWith(accessToken: null, isConnected: false),
        );
      }
      throw Exception(
        'Failed to refresh Shikimori token (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final newAccessToken = data['access_token'] as String;
    final newRefreshToken = (data['refresh_token'] as String?) ?? refreshToken;
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : DateTime.now().add(const Duration(days: 1));

    final updated = creds.copyWith(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresAt: expiresAt,
      isConnected: true,
    );
    await storage.saveCredentials(ServiceType.shikimori, updated);
    return updated;
  }

  ({String url, String codeVerifier}) prepareSimklAuth() {
    final creds = storage.getCredentials(ServiceType.simkl);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultSimklClientId;
    if (clientId.isEmpty) {
      throw Exception(
        'Brak Client ID dla Simkl. Skonfiguruj SIMKL_CLIENT_ID w pliku .env.',
      );
    }
    final verifier = generateSimklCodeVerifier();
    final challenge = generateSimklCodeChallenge(verifier);

    final url = Uri.https('simkl.com', '/oauth2/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': 'http://localhost',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'state': 'state',
      'scope': 'media:read media:write',
    }).toString();

    return (url: url, codeVerifier: verifier);
  }

  Future<ServiceCredentials> exchangeSimklToken({
    required String rawCodeOrUrl,
    required String codeVerifier,
  }) async {
    final code = extractCode(rawCodeOrUrl);
    if (code.isEmpty) {
      throw Exception('Authorization code cannot be empty');
    }

    final creds = storage.getCredentials(ServiceType.simkl);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultSimklClientId;
    final clientSecret = creds.clientSecret?.isNotEmpty == true
        ? creds.clientSecret!
        : StorageService.defaultSimklClientSecret;

    final resp = await http.post(
      Uri.parse('https://api.simkl.com/oauth2/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': 'http://localhost',
        'grant_type': 'authorization_code',
        'code_verifier': codeVerifier,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to exchange Simkl token (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    String? username;
    try {
      final userResp = await http.get(
        Uri.parse('https://api.simkl.com/users/settings'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'simkl-api-key': clientId,
        },
      );
      if (userResp.statusCode == 200) {
        final userData = jsonDecode(userResp.body) as Map<String, dynamic>;
        username = userData['user']?['name'] as String?;
      }
    } catch (_) {}

    return creds.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      username: username ?? creds.username,
      isConnected: true,
    );
  }

  Future<ServiceCredentials>? _simklRefreshFuture;

  Future<ServiceCredentials> refreshSimklToken() async {
    if (_simklRefreshFuture != null) {
      return await _simklRefreshFuture!;
    }
    final future = _performSimklRefresh();
    _simklRefreshFuture = future;
    try {
      return await future;
    } finally {
      _simklRefreshFuture = null;
    }
  }

  Future<ServiceCredentials> _performSimklRefresh() async {
    final creds = storage.getCredentials(ServiceType.simkl);
    final refreshToken = creds.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception(
        'No refresh token available for Simkl. Please log in again.',
      );
    }

    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultSimklClientId;
    final clientSecret = creds.clientSecret?.isNotEmpty == true
        ? creds.clientSecret!
        : StorageService.defaultSimklClientSecret;

    final resp = await _client.post(
      Uri.parse('https://api.simkl.com/oauth2/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': refreshToken,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to refresh Simkl token (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final newRefreshToken = (data['refresh_token'] as String?) ?? refreshToken;
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAt = DateTime.now().add(
      Duration(seconds: expiresIn ?? const Duration(days: 7).inSeconds),
    );

    final updated = creds.copyWith(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
      expiresAt: expiresAt,
      isConnected: true,
    );
    await storage.saveCredentials(ServiceType.simkl, updated);
    return updated;
  }

  Future<ServiceCredentials> loginKitsu({
    required String usernameOrEmail,
    required String password,
  }) async {
    if (usernameOrEmail.trim().isEmpty || password.isEmpty) {
      throw Exception('Username and password are required');
    }

    final creds = storage.getCredentials(ServiceType.kitsu);

    final resp = await http.post(
      Uri.parse('https://kitsu.app/api/oauth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'password',
        'username': usernameOrEmail.trim(),
        'password': password,
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Kitsu login failed (${resp.statusCode}): Check your credentials',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;

    String username = usernameOrEmail.trim();
    String? userId;
    try {
      final userResp = await http.get(
        Uri.parse('https://kitsu.app/api/edge/users?filter[self]=true'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/vnd.api+json',
        },
      );
      if (userResp.statusCode == 200) {
        final userData = jsonDecode(userResp.body) as Map<String, dynamic>;
        final users = (userData['data'] as List<dynamic>?) ?? [];
        if (users.isNotEmpty) {
          final first = users.first as Map<String, dynamic>;
          final fetchedId = first['id'] as String?;
          final fetchedName = first['attributes']?['name'] as String?;
          if (fetchedName != null && fetchedName.isNotEmpty) {
            username = fetchedName;
          }
          if (fetchedId != null && fetchedId.isNotEmpty) {
            userId = fetchedId;
          }
        }
      }
    } catch (_) {}

    return creds.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      username: username,
      userId: userId,
      isConnected: true,
    );
  }

  ({String url, String codeVerifier}) prepareMangaBakaAuth() {
    final creds = storage.getCredentials(ServiceType.mangabaka);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultMangaBakaClientId;
    if (clientId.isEmpty) {
      throw Exception(
        'Brak Client ID dla MangaBaka. Skonfiguruj MANGABAKA_CLIENT_ID w pliku .env.',
      );
    }
    final verifier = generateSimklCodeVerifier();
    final challenge = generateSimklCodeChallenge(verifier);

    final url = Uri.https('mangabaka.org', '/auth/oauth2/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': 'http://localhost',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'state': 'state',
      'scope': 'library.read library.write offline_access openid profile',
    }).toString();

    return (url: url, codeVerifier: verifier);
  }

  Future<ServiceCredentials> exchangeMangaBakaToken({
    required String rawCodeOrUrl,
    required String codeVerifier,
  }) async {
    final code = extractCode(rawCodeOrUrl);
    if (code.isEmpty) {
      throw Exception('Authorization code cannot be empty');
    }

    final creds = storage.getCredentials(ServiceType.mangabaka);
    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultMangaBakaClientId;

    final resp = await _client.post(
      Uri.parse('https://mangabaka.org/auth/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'AniSync/1.0.0',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'redirect_uri': 'http://localhost',
        'code': code,
        'code_verifier': codeVerifier,
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to exchange MangaBaka token (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    String? username;
    String? userId;
    try {
      final userResp = await _client.get(
        Uri.parse('https://mangabaka.org/auth/oauth2/userinfo'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'AniSync/1.0.0',
        },
      );
      if (userResp.statusCode == 200) {
        final userData = jsonDecode(userResp.body) as Map<String, dynamic>;
        username =
            (userData['name'] as String?) ??
            (userData['preferred_username'] as String?);
        userId = userData['sub']?.toString();
      }
    } catch (_) {}

    final updated = creds.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      username: username ?? creds.username,
      userId: userId ?? creds.userId,
      isConnected: true,
    );

    await storage.saveCredentials(ServiceType.mangabaka, updated);
    return updated;
  }

  Future<ServiceCredentials>? _mangaBakaRefreshFuture;

  Future<ServiceCredentials> refreshMangaBakaToken() async {
    if (_mangaBakaRefreshFuture != null) {
      return await _mangaBakaRefreshFuture!;
    }
    final future = _performMangaBakaRefresh();
    _mangaBakaRefreshFuture = future;
    try {
      return await future;
    } finally {
      _mangaBakaRefreshFuture = null;
    }
  }

  Future<ServiceCredentials> _performMangaBakaRefresh() async {
    final creds = storage.getCredentials(ServiceType.mangabaka);
    final refreshToken = creds.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception(
        'No refresh token available for MangaBaka. Please log in again.',
      );
    }

    final clientId = creds.clientId?.isNotEmpty == true
        ? creds.clientId!
        : StorageService.defaultMangaBakaClientId;

    final resp = await _client.post(
      Uri.parse('https://mangabaka.org/auth/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'AniSync/1.0.0',
      },
      body: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'refresh_token': refreshToken,
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to refresh MangaBaka token (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final newAccessToken = data['access_token'] as String;
    final newRefreshToken = (data['refresh_token'] as String?) ?? refreshToken;
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    final updated = creds.copyWith(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresAt: expiresAt,
      isConnected: true,
    );

    await storage.saveCredentials(ServiceType.mangabaka, updated);
    return updated;
  }

  Future<HttpServer?> tryStartLoopbackServer(
    void Function(String code) onCodeReceived,
  ) async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 80);
      server.listen((request) async {
        final code = request.uri.queryParameters['code'];
        request.response.headers.contentType = ContentType.html;
        request.response.write('''
          <!DOCTYPE html>
          <html>
            <head><meta charset="utf-8"><title>AniSync Authorized</title></head>
            <body style="font-family:system-ui,sans-serif;text-align:center;padding:50px;background:#121212;color:#fff;">
              <h1 style="color:#4caf50;">Authorization Successful!</h1>
              <p>You can close this window and return to the AniSync application.</p>
            </body>
          </html>
        ''');
        await request.response.close();
        if (code != null && code.isNotEmpty) {
          onCodeReceived(code);
        }
      });
      return server;
    } catch (_) {
      return null;
    }
  }
}
