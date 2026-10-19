import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class AnilistRateLimiter {
  static DateTime? _resetUntil;
  static int _remaining = 90;
  static DateTime? _lastRequestTime;

  @visibleForTesting
  static http.Client? testClient;

  @visibleForTesting
  static void resetState() {
    _resetUntil = null;
    _remaining = 90;
    _lastRequestTime = null;
    testClient = null;
  }

  static bool get isTestEnvironment {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  static Future<http.Response> post({
    required Uri url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 15),
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      if (_resetUntil != null) {
        final now = DateTime.now();
        if (now.isBefore(_resetUntil!)) {
          final waitDuration = _resetUntil!.difference(now);
          debugPrint('AniListRateLimiter: waiting ${waitDuration.inMilliseconds}ms for cooldown');
          await Future.delayed(waitDuration);
        }
      }

      if (!isTestEnvironment) {
        if (_remaining <= 5) {
          debugPrint('AniListRateLimiter: quota low ($_remaining remaining), throttling 1000ms');
          await Future.delayed(const Duration(milliseconds: 1000));
        } else if (_lastRequestTime != null) {
          final elapsed = DateTime.now().difference(_lastRequestTime!);
          if (elapsed < const Duration(milliseconds: 150)) {
            await Future.delayed(const Duration(milliseconds: 150) - elapsed);
          }
        }
      }

      _lastRequestTime = DateTime.now();

      final client = testClient;
      final resp = client != null
          ? await client
              .post(url, headers: headers, body: jsonEncode(body))
              .timeout(timeout)
          : await http
              .post(url, headers: headers, body: jsonEncode(body))
              .timeout(timeout);

      final remainingHeader = resp.headers['x-ratelimit-remaining'];
      if (remainingHeader != null) {
        _remaining = int.tryParse(remainingHeader) ?? _remaining;
      }
      bool isRateLimited = resp.statusCode == 429;
      if (!isRateLimited && resp.statusCode == 200 && resp.body.contains('"status": 429')) {
        isRateLimited = true;
      }

      if (isRateLimited) {
        final retryAfterHeader = resp.headers['retry-after'] ?? resp.headers['Retry-After'];
        int retrySeconds = int.tryParse(retryAfterHeader ?? '3') ?? 3;
        if (retrySeconds < 2) retrySeconds = 2;
        if (retrySeconds > 15) retrySeconds = 15;

        _resetUntil = DateTime.now().add(Duration(seconds: retrySeconds + 1));
        debugPrint('AniList returned 429: waiting ${retrySeconds}s before retry (attempt ${attempt + 1}/$maxRetries)...');

        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: retrySeconds + 1));
          continue;
        }
      }

      return resp;
    }

    throw Exception('AniList request failed after $maxRetries retries');
  }
}
