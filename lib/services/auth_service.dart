import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import '../models/diagnostic_state.dart';
import 'firebase_service.dart';
import 'server_connectivity_service.dart';
import 'ticket_service.dart';
import 'user_prefs_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  String? _token;
  AppUserProfile? _profile;
  bool _initialized = false;

  String? get token => _token;
  AppUserProfile? get profile => _profile;
  bool get isLoggedIn => _token != null && _profile != null;
  bool get isAdmin => _profile?.role == AppRole.admin;

  Future<void> initialize() async {
    _token = await UserPrefsService.loadAuthToken();
    if (_token == null) {
      _profile = null;
      _initialized = true;
      return;
    }
    try {
      await _fetchMe();
    } catch (_) {
      await signOut();
    }
    _initialized = true;
  }

  Future<void> waitUntilReady() async {
    if (_initialized) return;
    await initialize();
  }

  String get _apiBase => ServerConnectivityService.instance.apiBaseUrl;

  Map<String, String> authHeaders({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  static bool isValidPassword(String password) {
    if (password.length < 8 || password.length > 16) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(password)) {
      return false;
    }
    return true;
  }

  static String passwordRequirementsText =
      '8–16 characters with uppercase, lowercase, number, and symbol.';

  Future<AppUserProfile> signUp({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    required AppRole role,
  }) async {
    if (!isValidPassword(password)) {
      throw AuthException(passwordRequirementsText);
    }

    final res = await http.post(
      Uri.parse('$_apiBase/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'role': role.firestoreValue,
      }),
    );

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw AuthException(data['error']?.toString() ?? 'Registration failed.');
    }

    final profile = _profileFromJson(data['user'] as Map<String, dynamic>);
    await FirebaseService.instance.saveUserProfile(profile);
    return profile;
  }

  Future<AppUserProfile> signIn({
    required String email,
    required String password,
    required LoginPortal portal,
  }) async {
    final res = await http.post(
      Uri.parse('$_apiBase/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw AuthException(data['error']?.toString() ?? 'Login failed.');
    }

    final profile = _profileFromJson(data['user'] as Map<String, dynamic>);
    final expectedRole = portal == LoginPortal.admin ? AppRole.admin : AppRole.user;
    if (profile.role != expectedRole) {
      throw AuthException(
        'This account is registered as ${profile.role.label}, not ${portal.label}. '
        'Please choose the correct login type.',
      );
    }

    return _applySession(data);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final res = await http.post(
      Uri.parse('$_apiBase/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw AuthException(data['error']?.toString() ?? 'Could not send verification code.');
    }
    if (kDebugMode && data['devCode'] != null) {
      debugPrint('[Auth] Dev reset code: ${data['devCode']}');
    }
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (!isValidPassword(newPassword)) {
      throw AuthException(passwordRequirementsText);
    }
    final res = await http.post(
      Uri.parse('$_apiBase/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw AuthException(data['error']?.toString() ?? 'Password reset failed.');
    }
  }

  Future<void> signOut() async {
    _token = null;
    _profile = null;
    await UserPrefsService.clearAuthSession();
    notifyListeners();
  }

  Future<AppUserProfile?> getCurrentProfile() async {
    if (!_initialized) await initialize();
    return _profile;
  }

  Future<void> _fetchMe() async {
    final res = await http.get(
      Uri.parse('$_apiBase/auth/me'),
      headers: authHeaders(),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw AuthException(data['error']?.toString() ?? 'Session expired.');
    }
    _profile = _profileFromJson(data['user'] as Map<String, dynamic>);
    await UserPrefsService.saveUsername(_profile!.displayName);
    await DiagnosticState().loadUserProfile();
    await FirebaseService.instance.saveUserProfile(_profile!);
    notifyListeners();
  }

  Future<AppUserProfile> _applySession(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _profile = _profileFromJson(data['user'] as Map<String, dynamic>);
    await UserPrefsService.saveAuthSession(
      token: _token!,
      role: _profile!.role.firestoreValue,
      email: _profile!.email,
      displayName: _profile!.displayName,
    );
    await DiagnosticState().loadUserProfile();
    await FirebaseService.instance.saveUserProfile(_profile!);
    await TicketService.instance.load();
    notifyListeners();
    return _profile!;
  }

  AppUserProfile _profileFromJson(Map<String, dynamic> json) {
    return AppUserProfile(
      uid: json['id'].toString(),
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: AppRole.fromString(json['role'] as String?),
    );
  }
}
