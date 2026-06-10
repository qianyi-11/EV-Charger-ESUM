import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsService {
  UserPrefsService._();

  static const _usernameKey = 'user_display_name';
  static const _darkThemeKey = 'app_dark_theme';
  static const _recentActivityKey = 'recent_activity';
  static const _authTokenKey = 'auth_jwt_token';
  static const _authRoleKey = 'auth_user_role';
  static const _authEmailKey = 'auth_user_email';

  static Future<String> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? 'EV User';
  }

  static Future<void> saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name.trim());
  }

  static Future<bool> loadDarkTheme({bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkThemeKey) ?? defaultValue;
  }

  static Future<void> saveDarkTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkThemeKey, isDark);
  }

  static Future<String?> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<void> saveAuthSession({
    required String token,
    required String role,
    required String email,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    await prefs.setString(_authRoleKey, role);
    await prefs.setString(_authEmailKey, email);
    await prefs.setString(_usernameKey, displayName);
  }

  static Future<String?> loadAuthRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authRoleKey);
  }

  static Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_authRoleKey);
    await prefs.remove(_authEmailKey);
  }

  static Future<List<Map<String, dynamic>>> loadRecentActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentActivityKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveRecentActivity(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentActivityKey, jsonEncode(items));
  }
}
