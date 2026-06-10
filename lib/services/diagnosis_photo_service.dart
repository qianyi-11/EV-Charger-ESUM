import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import 'server_connectivity_service.dart';

/// Uploads diagnosis photos to the server as soon as they are captured.
class DiagnosisPhotoService {
  static Future<String?> uploadToServer(File file, {required String kind}) async {
    if (!await file.exists()) return null;

    await AuthService.instance.waitUntilReady();
    if (!AuthService.instance.isLoggedIn) return null;

    try {
      final base = ServerConnectivityService.instance.apiBaseUrl;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/tickets/diagnosis-photos?kind=$kind'),
      );
      request.headers.addAll(AuthService.instance.authHeaders(json: false));
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 400) {
        if (kDebugMode) {
          debugPrint('[DiagnosisPhoto] upload failed: ${data['error']}');
        }
        return null;
      }

      return data['filename'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('[DiagnosisPhoto] upload error: $e');
      return null;
    }
  }
}
