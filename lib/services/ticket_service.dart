import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/support_ticket.dart';
import 'auth_service.dart';
import 'server_connectivity_service.dart';

class TicketService extends ChangeNotifier {
  TicketService._();
  static final TicketService instance = TicketService._();

  List<SupportTicket> _tickets = [];

  List<SupportTicket> get tickets => List.unmodifiable(_tickets);

  String get _apiBase => ServerConnectivityService.instance.apiBaseUrl;

  Future<void> load() async {
    await AuthService.instance.waitUntilReady();
    if (!AuthService.instance.isLoggedIn) {
      _tickets = [];
      notifyListeners();
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$_apiBase/tickets'),
        headers: AuthService.instance.authHeaders(json: false),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        throw Exception(data['error'] ?? 'Failed to load tickets');
      }
      final list = data['tickets'] as List<dynamic>? ?? [];
      _tickets = list
          .map((e) => SupportTicket.fromApiJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[TicketService] load error: $e');
      _tickets = [];
    }
    notifyListeners();
  }

  Future<SupportTicket> addTicket(
    SupportTicket ticket, {
    File? eboxScreenshot,
    File? isolatorPhoto,
    File? evdbPhoto,
    String? isolatorPhotoFilename,
    String? evdbPhotoFilename,
  }) async {
    final payload = {
      'salutation': ticket.salutation,
      'fullName': ticket.fullName,
      'contactNumber': ticket.contactNumber,
      'address': ticket.address,
      'carBrand': ticket.carBrand,
      'carBrandOther': ticket.carBrandOther,
      'installedWithRexharge': ticket.installedWithRexharge,
      'chargerBrand': ticket.chargerBrand,
      'chargerBrandOther': ticket.chargerBrandOther,
      'chargerSerialNumber': ticket.chargerSerialNumber,
      'installationDate': ticket.installationDate?.toIso8601String(),
      'faultyComponent': ticket.faultyComponent,
      'describeIssue': ticket.describeIssue,
      'details': ticket.details,
      'sourceErrorCode': ticket.sourceErrorCode,
    };

    if (isolatorPhotoFilename != null && isolatorPhotoFilename.isNotEmpty) {
      payload['isolatorPhotoFilename'] = isolatorPhotoFilename;
    }
    if (evdbPhotoFilename != null && evdbPhotoFilename.isNotEmpty) {
      payload['evdbPhotoFilename'] = evdbPhotoFilename;
    }

    final http.Response res;
    final hasFileUploads =
        eboxScreenshot != null ||
        (isolatorPhoto != null && isolatorPhotoFilename == null) ||
        (evdbPhoto != null && evdbPhotoFilename == null);
    if (hasFileUploads) {
      final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/tickets'));
      request.headers.addAll(AuthService.instance.authHeaders(json: false));
      request.fields['data'] = jsonEncode(payload);
      if (eboxScreenshot != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'eboxScreenshot',
          eboxScreenshot.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (isolatorPhoto != null && isolatorPhotoFilename == null) {
        request.files.add(await http.MultipartFile.fromPath(
          'isolatorPhoto',
          isolatorPhoto.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (evdbPhoto != null && evdbPhotoFilename == null) {
        request.files.add(await http.MultipartFile.fromPath(
          'evdbPhoto',
          evdbPhoto.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      final streamed = await request.send();
      res = await http.Response.fromStream(streamed);
    } else {
      res = await http.post(
        Uri.parse('$_apiBase/tickets'),
        headers: AuthService.instance.authHeaders(),
        body: jsonEncode(payload),
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to submit ticket');
    }

    final saved = SupportTicket.fromApiJson(
      Map<String, dynamic>.from(data['ticket'] as Map),
    );
    _tickets.insert(0, saved);
    notifyListeners();
    return saved;
  }
}
