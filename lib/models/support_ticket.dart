import 'detected_fault.dart';

class SupportTicket {
  final String id;
  final DateTime createdAt;
  final String salutation;
  final String fullName;
  final String contactNumber;
  final String address;
  final String carBrand;
  final String? carBrandOther;
  final String installedWithRexharge;
  final String chargerBrand;
  final String? chargerBrandOther;
  final String chargerSerialNumber;
  final DateTime? installationDate;
  final String faultyComponent;
  final String? describeIssue;
  final String details;
  final String? sourceErrorCode;
  final String status;
  final String? assignedEngineer;
  final String? issueType;
  final int? ticketNumber;

  const SupportTicket({
    required this.id,
    required this.createdAt,
    required this.salutation,
    required this.fullName,
    required this.contactNumber,
    required this.address,
    required this.carBrand,
    this.carBrandOther,
    required this.installedWithRexharge,
    required this.chargerBrand,
    this.chargerBrandOther,
    required this.chargerSerialNumber,
    this.installationDate,
    required this.faultyComponent,
    this.describeIssue,
    required this.details,
    this.sourceErrorCode,
    this.status = 'open',
    this.assignedEngineer,
    this.issueType,
    this.ticketNumber,
  });

  String get ticketIdLabel =>
      ticketNumber != null ? '#$ticketNumber' : '#$id';

  String get displayTitle {
    if (issueType != null && issueType!.isNotEmpty) return issueType!;
    if (describeIssue != null && describeIssue!.isNotEmpty) {
      return describeIssue!;
    }
    if (faultyComponent == 'Other') return 'Other issue';
    return faultyComponent;
  }

  String get displaySubtitle => '$fullName · ${chargerSerialNumber.isNotEmpty ? chargerSerialNumber : 'No S/N'}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'salutation': salutation,
        'fullName': fullName,
        'contactNumber': contactNumber,
        'address': address,
        'carBrand': carBrand,
        'carBrandOther': carBrandOther,
        'installedWithRexharge': installedWithRexharge,
        'chargerBrand': chargerBrand,
        'chargerBrandOther': chargerBrandOther,
        'chargerSerialNumber': chargerSerialNumber,
        'installationDate': installationDate?.toIso8601String(),
        'faultyComponent': faultyComponent,
        'describeIssue': describeIssue,
        'details': details,
        'sourceErrorCode': sourceErrorCode,
      };

  factory SupportTicket.fromApiJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id']?.toString() ?? '',
        ticketNumber: json['ticketNumber'] as int?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        salutation: json['salutation'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        contactNumber: json['contactNumber'] as String? ?? '',
        address: json['address'] as String? ?? '',
        carBrand: json['carBrand'] as String? ?? '',
        carBrandOther: json['carBrandOther'] as String?,
        installedWithRexharge: json['installedWithRexharge'] as String? ?? '',
        chargerBrand: json['chargerBrand'] as String? ?? '',
        chargerBrandOther: json['chargerBrandOther'] as String?,
        chargerSerialNumber: json['chargerSerialNumber'] as String? ?? '',
        installationDate: json['installationDate'] != null
            ? DateTime.tryParse(json['installationDate'] as String)
            : null,
        faultyComponent: json['faultyComponent'] as String? ?? '',
        describeIssue: json['describeIssue'] as String?,
        issueType: json['issueType'] as String?,
        details: json['details'] as String? ?? '',
        sourceErrorCode: json['sourceErrorCode'] as String?,
        status: json['status'] as String? ?? 'open',
        assignedEngineer: json['assignedEngineer'] as String?,
      );

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        salutation: json['salutation'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        contactNumber: json['contactNumber'] as String? ?? '',
        address: json['address'] as String? ?? '',
        carBrand: json['carBrand'] as String? ?? '',
        carBrandOther: json['carBrandOther'] as String?,
        installedWithRexharge: json['installedWithRexharge'] as String? ?? '',
        chargerBrand: json['chargerBrand'] as String? ?? '',
        chargerBrandOther: json['chargerBrandOther'] as String?,
        chargerSerialNumber: json['chargerSerialNumber'] as String? ?? '',
        installationDate: json['installationDate'] != null
            ? DateTime.tryParse(json['installationDate'] as String)
            : null,
        faultyComponent: json['faultyComponent'] as String? ?? '',
        describeIssue: json['describeIssue'] as String?,
        details: json['details'] as String? ?? '',
        sourceErrorCode: json['sourceErrorCode'] as String?,
      );
}

/// Optional prefill when opening the form from a diagnosis result.
class TicketPrefill {
  final String? faultyComponent;
  final String? describeIssue;
  final String? chargerSerialNumber;
  final String? sourceErrorCode;
  final String? details;

  const TicketPrefill({
    this.faultyComponent,
    this.describeIssue,
    this.chargerSerialNumber,
    this.sourceErrorCode,
    this.details,
  });

  static TicketPrefill? fromRouteArgs(Object? args) {
    if (args is TicketPrefill) return args;
    if (args is Map<String, dynamic>) {
      return TicketPrefill(
        faultyComponent: args['faultyComponent'] as String?,
        describeIssue: args['describeIssue'] as String?,
        chargerSerialNumber: args['chargerSerialNumber'] as String?,
        sourceErrorCode: args['sourceErrorCode'] as String?,
        details: args['details'] as String?,
      );
    }
    return null;
  }

  static TicketPrefill fromErrorCode(String errorCode) {
    final code = errorCode.toLowerCase();
    if (code == 'power-cut') {
      return TicketPrefill(
        faultyComponent: 'Isolator',
        describeIssue: 'Isolator OFF',
        sourceErrorCode: errorCode,
      );
    }
    if (code == 'supply-issue') {
      return TicketPrefill(
        faultyComponent: 'Charger',
        describeIssue: 'No light',
        sourceErrorCode: errorCode,
      );
    }
    if (code == 'solid-red' || code == 'charger-issue') {
      return TicketPrefill(
        faultyComponent: 'Charger',
        describeIssue: 'Solid red light',
        sourceErrorCode: errorCode,
      );
    }
    if (code == 'blink-6') {
      return TicketPrefill(
        faultyComponent: 'Charger',
        describeIssue: 'Red light flashes 6 times',
        sourceErrorCode: errorCode,
      );
    }
    if (code == 'blink-7') {
      return TicketPrefill(
        faultyComponent: 'Charger',
        describeIssue: 'Red light flashes 7 times',
        sourceErrorCode: errorCode,
      );
    }
    if (code == 'blink-8') {
      return TicketPrefill(
        faultyComponent: 'Charger',
        describeIssue: 'Red light flashes 8 times',
        sourceErrorCode: errorCode,
      );
    }
    if (code == 'blink-9') {
      return TicketPrefill(
        faultyComponent: 'Charger',
        describeIssue: 'Red light flashes 9 times',
        sourceErrorCode: errorCode,
      );
    }
    if (code == 'protection-issue') {
      return TicketPrefill(
        faultyComponent: 'EVDB',
        sourceErrorCode: errorCode,
      );
    }
    return TicketPrefill(sourceErrorCode: errorCode);
  }

  /// Builds ticket prefill using live scan findings (e.g. EVDB spec mismatch).
  static TicketPrefill fromDiagnosis(String errorCode, {List<String> scanFindings = const []}) {
    final base = fromErrorCode(errorCode);
    if (errorCode.toLowerCase() != 'protection-issue' || scanFindings.isEmpty) {
      return base;
    }

    final missingMcb = scanFindings.any((f) => f.toLowerCase().contains('mcb missing'));
    final missingRccb = scanFindings.any((f) => f.toLowerCase().contains('rccb missing'));
    final specIssues = scanFindings.where((issue) {
      final lower = issue.toLowerCase();
      return !lower.contains('mcb missing') && !lower.contains('rccb missing');
    }).toList();

    String? describeIssue;
    String? details;

    if (specIssues.isNotEmpty) {
      describeIssue = 'Wrong Component / Specs';
      final summaries = specIssues
          .map(FaultCatalog.phaseMismatchSummary)
          .whereType<String>()
          .toSet()
          .toList();
      if (summaries.isNotEmpty) {
        details = 'Incorrect phase. ${summaries.join(' ')}';
      } else {
        details = specIssues.join('\n');
      }
    } else if (missingMcb && !missingRccb) {
      describeIssue = 'Missing MCB';
    } else if (missingRccb && !missingMcb) {
      describeIssue = 'Missing RCCB';
    } else if (missingMcb && missingRccb) {
      describeIssue = 'Missing MCB';
    }

    return TicketPrefill(
      faultyComponent: 'EVDB',
      describeIssue: describeIssue ?? base.describeIssue,
      details: details,
      sourceErrorCode: errorCode,
    );
  }
}
