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
}

/// Canonical fault text from the EV charger diagnostic specification.
class FaultCatalog {
  static const ticketFollowUp =
      'If the issue still persists, please proceed using the "Create Ticket" button below for further inspection.';

  static const missingMcb = DetectedFault(
    component: 'MCB / RCCB',
    faultType: 'Protection Issue',
    faultDetail: 'Missing MCB.',
    recommendedAction: ticketFollowUp,
  );

  static const missingRccb = DetectedFault(
    component: 'MCB / RCCB',
    faultType: 'Protection Issue',
    faultDetail: 'Missing RCCB.',
    recommendedAction: ticketFollowUp,
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
    recommendedAction: ticketFollowUp,
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
    recommendedAction: ticketFollowUp,
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
    final detail = specIssues.isEmpty
        ? 'Wrong component specifications.'
        : 'Wrong component specifications. ${specIssues.join(' ')}';
    return DetectedFault(
      component: 'MCB / RCCB',
      faultType: 'Protection Issue',
      faultDetail: detail,
      recommendedAction: ticketFollowUp,
    );
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
