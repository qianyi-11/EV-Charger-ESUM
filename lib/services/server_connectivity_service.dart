import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Resolves and caches the dev machine backend URL so chat/vision APIs stay stable.
class ServerConnectivityService {
  ServerConnectivityService._();
  static final ServerConnectivityService instance = ServerConnectivityService._();

  String? _resolvedVisionBaseUrl;
  bool _initialized = false;

  String get visionBaseUrl =>
      _resolvedVisionBaseUrl ?? ApiConfig.hostToVisionBaseUrl(ApiConfig.defaultDevServerHost);

  String get apiBaseUrl => visionBaseUrl.replaceFirst('/api/vision', '/api');

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    // Always reinitialize to check for updated server host
    _initialized = false;
    _resolvedVisionBaseUrl = null;
    _resolvedVisionBaseUrl = await resolveVisionBaseUrl();
    _initialized = true;
    if (kDebugMode) {
      debugPrint('[ServerConnectivity] Using $visionBaseUrl');
    }
  }

  Future<String?> getSavedHost() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString(ApiConfig.prefsHostKey)?.trim();
    if (host == null || host.isEmpty) return null;
    return host;
  }

  Future<void> saveHost(String host) async {
    final trimmed = host.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(ApiConfig.prefsHostKey);
    } else {
      await prefs.setString(ApiConfig.prefsHostKey, trimmed);
    }
    _resolvedVisionBaseUrl = null;
    _initialized = false;
    await initialize();
  }

  Future<List<String>> candidateHosts() async {
    final hosts = <String>[];
    void add(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      if (!hosts.contains(trimmed)) hosts.add(trimmed);
    }

    add(ApiConfig.buildTimeHost);
    add(await getSavedHost());
    add(ApiConfig.defaultDevServerHost);

    if (!kIsWeb && Platform.isAndroid) {
      add('10.0.2.2'); // Android emulator → host machine localhost
    }

    return hosts;
  }

  Future<String> resolveVisionBaseUrl({bool forceRefresh = false}) async {
    // Always try the default host first (highest priority)
    if (await _probeHealth(ApiConfig.defaultDevServerHost)) {
      final url = ApiConfig.hostToVisionBaseUrl(ApiConfig.defaultDevServerHost);
      _resolvedVisionBaseUrl = url;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConfig.prefsResolvedUrlKey, url);
      await prefs.setString(ApiConfig.prefsHostKey, ApiConfig.defaultDevServerHost);
      if (kDebugMode) {
        debugPrint('[ServerConnectivity] Using default host: $url');
      }
      return url;
    }

    // Then try cached URL if available
    if (!forceRefresh && _resolvedVisionBaseUrl != null) {
      return _resolvedVisionBaseUrl!;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cached = prefs.getString(ApiConfig.prefsResolvedUrlKey);
      if (cached != null && cached.isNotEmpty) {
        final host = _hostFromVisionUrl(cached);
        if (host != null && await _probeHealth(host)) {
          _resolvedVisionBaseUrl = cached;
          return cached;
        }
      }
    }

    for (final host in await candidateHosts()) {
      if (await _probeHealth(host)) {
        final url = ApiConfig.hostToVisionBaseUrl(host);
        _resolvedVisionBaseUrl = url;
        await prefs.setString(ApiConfig.prefsResolvedUrlKey, url);
        await prefs.setString(ApiConfig.prefsHostKey, host);
        return url;
      }
    }

    final fallbackHost = await getSavedHost() ??
        (ApiConfig.buildTimeHost.isNotEmpty
            ? ApiConfig.buildTimeHost
            : ApiConfig.defaultDevServerHost);
    final fallback = ApiConfig.hostToVisionBaseUrl(fallbackHost);
    _resolvedVisionBaseUrl = fallback;
    return fallback;
  }

  Future<bool> testHost(String host) => _probeHealth(host.trim());

  Future<bool> _probeHealth(String host) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.hostToHealthUrl(host)),
            headers: const {'Bypass-Tunnel-Reminder': 'true'},
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String? _hostFromVisionUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return null;
      return uri.host;
    } catch (_) {
      return null;
    }
  }
}
