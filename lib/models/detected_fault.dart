class DetectedFault {
  final String component;
  final String faultType;
  final String faultDetail;
  final String recommendedAction;

  const DetectedFault({
    this.component = '',
    required this.faultType,
    required this.faultDetail,
    required this.recommendedAction,
  });

  Map<String, dynamic> toMap() => {
        'component': component,
        'faultType': faultType,
        'faultDetail': faultDetail,
        'recommendedAction': recommendedAction,
      };

  factory DetectedFault.fromMap(Map<String, dynamic> map) => DetectedFault(
        component: map['component']?.toString() ?? '',
        faultType: map['faultType']?.toString() ?? '',
        faultDetail: map['faultDetail']?.toString() ?? '',
        recommendedAction: map['recommendedAction']?.toString() ?? '',
      );
}

/// Canonical fault text from the EV charger diagnostic specification.
class FaultCatalog {
  static const createTicketAction =
      'Please proceed using the "Create Ticket" button below for further inspection.';

  static const ticketFollowUp =
      'If the issue still persists, please proceed using the "Create Ticket" button below for further inspection.';

  static const missingMcb = DetectedFault(
    component: 'MCB / RCCB',
    faultType: 'Protection Issue',
    faultDetail: 'Missing MCB.',
    recommendedAction: createTicketAction,
  );

  static const missingRccb = DetectedFault(
    component: 'MCB / RCCB',
    faultType: 'Protection Issue',
    faultDetail: 'Missing RCCB.',
    recommendedAction: createTicketAction,
  );

  static const isolatorOff = DetectedFault(
    component: 'Isolator',
    faultType: 'Power Cut',
    faultDetail: 'Isolator is switched OFF.',
    recommendedAction:
        'Please turn ON the Isolator and check whether the breaker in the EVDB has tripped. $ticketFollowUp',
  );

  static const groundFault = DetectedFault(
    component: 'Charger',
    faultType: 'Installation Issue',
    faultDetail: 'Red light flashes 6 times, indicating a Ground Fault.',
    recommendedAction: createTicketAction,
  );

  static const emergencyStop = DetectedFault(
    component: 'Charger',
    faultType: 'Manual Error',
    faultDetail: 'Red light flashes 7 times, indicating an Emergency Stop Button Error.',
    recommendedAction:
        'Please release the Emergency Stop button. $ticketFollowUp',
  );

  static const shortCircuit = DetectedFault(
    component: 'Charger',
    faultType: 'Charger Issue',
    faultDetail: 'Red light flashes 8 times, indicating a Short Circuit.',
    recommendedAction: createTicketAction,
  );

  static const overTemperature = DetectedFault(
    component: 'Charger',
    faultType: 'Charger Issue',
    faultDetail: 'Red light flashes 9 times, indicating an Over-temperature error.',
    recommendedAction:
        'Please shut down the charger for a while and restart it. $ticketFollowUp',
  );

  static const solidRedLight = DetectedFault(
    component: 'Charger',
    faultType: 'Charger Issue',
    faultDetail: 'Solid Red Light.',
    recommendedAction:
        'Please take a screenshot of the app error status. $ticketFollowUp',
  );

  static const noLight = DetectedFault(
    faultType: 'Supply Issue',
    faultDetail: 'Charger No Light',
    recommendedAction:
        'Please check whether the main breaker in the EVDB has tripped. $ticketFollowUp',
  );

  static DetectedFault wrongSpecs(List<String> specIssues) {
    return DetectedFault(
      component: 'MCB / RCCB',
      faultType: 'Protection Issue',
      faultDetail: 'Wrong component specifications.',
      recommendedAction: createTicketAction,
    );
  }

  static String _phaseDescription(int phases) {
    switch (phases) {
      case 1:
        return 'single-phase';
      case 3:
        return 'three-phase';
      default:
        return '$phases-phase';
    }
  }

  static ({String component, int supplyPhases, int requiredPhases})? _parsePhaseMismatch(
    String issue,
  ) {
    if (!issue.toLowerCase().contains('phase mismatch')) return null;

    final componentMatch =
        RegExp(r'^(\w+)\s+phase mismatch', caseSensitive: false).firstMatch(issue);
    final component = componentMatch?.group(1) ?? 'Breaker';

    final newFmt = RegExp(
      r'phase mismatch:\s*(\d+)\s*phase supply,\s*spec required (\d+)\s*phase',
      caseSensitive: false,
    ).firstMatch(issue);
    if (newFmt != null) {
      return (
        component: component,
        supplyPhases: int.parse(newFmt.group(1)!),
        requiredPhases: int.parse(newFmt.group(2)!),
      );
    }

    final oldFmt = RegExp(
      r'\((\d+)-phase supply[^)]*spec requires (\d+)-phase',
      caseSensitive: false,
    ).firstMatch(issue);
    if (oldFmt != null) {
      return (
        component: component,
        supplyPhases: int.parse(oldFmt.group(1)!),
        requiredPhases: int.parse(oldFmt.group(2)!),
      );
    }

    return null;
  }

  /// Short phase summary for tickets, e.g. "3 phase supply, spec required 1 phase."
  static String? phaseMismatchSummary(String issue) {
    final parsed = _parsePhaseMismatch(issue);
    if (parsed == null) return null;
    return '${parsed.supplyPhases} phase supply, spec required ${parsed.requiredPhases} phase.';
  }

  /// Plain-language phase mismatch line for the diagnosis result page.
  static String humanizePhaseMismatchFinding(String issue) {
    final parsed = _parsePhaseMismatch(issue);
    if (parsed == null) return issue;

    final supply = _phaseDescription(parsed.supplyPhases);
    final required = _phaseDescription(parsed.requiredPhases);
    switch (parsed.component.toUpperCase()) {
      case 'MCB':
        return 'The main circuit breaker (MCB) is set up for $supply power, '
            'but your charger label requires $required.';
      case 'RCCB':
        return 'The earth leakage breaker (RCCB) is set up for $supply power, '
            'but your charger label requires $required.';
      default:
        return 'The ${parsed.component} is set up for $supply power, '
            'but your charger label requires $required.';
    }
  }

  /// Simplified finding line for result page analysis section.
  static String simplifySpecFinding(String issue) {
    if (!issue.toLowerCase().contains('phase mismatch')) return issue;
    return humanizePhaseMismatchFinding(issue);
  }

  static List<DetectedFault> fromEvdbAnalysis({
    required bool mcbDetected,
    required bool rccbDetected,
    required List<String> issues,
  }) {
    final faults = <DetectedFault>[];
    if (!mcbDetected) faults.add(missingMcb);
    if (!rccbDetected) faults.add(missingRccb);

    final specIssues = issues.where((issue) {
      final lower = issue.toLowerCase();
      return !lower.contains('mcb missing') && !lower.contains('rccb missing');
    }).toList();

    if (specIssues.isNotEmpty) {
      faults.add(wrongSpecs(specIssues));
    }

    return faults;
  }

  static DetectedFault? forBlinkCount(int blinkCount) {
    switch (blinkCount) {
      case 6:
        return groundFault;
      case 7:
        return emergencyStop;
      case 8:
        return shortCircuit;
      case 9:
        return overTemperature;
      default:
        return null;
    }
  }

  static String normalizeErrorCode(String code) {
    if (code == 'solid-red') return 'solid-red';
    final match = RegExp(r'^blink-(\d+)').firstMatch(code);
    if (match != null) return 'blink-${match.group(1)}';
    return code;
  }

  static List<DetectedFault> forErrorCode(
    String errorCode, {
    List<String> scanFindings = const [],
    int blinkCount = 0,
  }) {
    final code = normalizeErrorCode(errorCode);

    switch (code) {
      case 'power-cut':
        return [isolatorOff];
      case 'supply-issue':
        return [noLight];
      case 'solid-red':
      case 'charger-issue':
        return [solidRedLight];
      case 'blink-6':
        return [groundFault];
      case 'blink-7':
        return [emergencyStop];
      case 'blink-8':
        return [shortCircuit];
      case 'blink-9':
        return [overTemperature];
      case 'protection-issue':
        if (scanFindings.isNotEmpty) {
          final missingMcb = scanFindings.any((f) => f.toLowerCase().contains('mcb missing'));
          final missingRccb = scanFindings.any((f) => f.toLowerCase().contains('rccb missing'));
          final specIssues = scanFindings.where((issue) {
            final lower = issue.toLowerCase();
            return !lower.contains('mcb missing') && !lower.contains('rccb missing');
          }).toList();
          return fromEvdbAnalysis(
            mcbDetected: !missingMcb,
            rccbDetected: !missingRccb,
            issues: specIssues.isNotEmpty ? specIssues : scanFindings,
          );
        }
        return [missingMcb];
      default:
        if (blinkCount > 0) {
          final fault = forBlinkCount(blinkCount);
          if (fault != null) return [fault];
        }
        return const [];
    }
  }
}
