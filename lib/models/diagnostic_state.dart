// diagnostic_state.dart
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'detected_fault.dart';

enum DiagnosisSeverity { info, warning, critical }
 
class DiagnosisInfo {
  final String code;         // Short display code  e.g. "E-PWR"
  final String name;         // Fault type label    e.g. "Power Cut"
  final String subTitle;     // One-liner situation description
  final String description;  // Longer explanation shown in result card
  final DiagnosisSeverity severity;
  final double confidence;
  final bool autoContact;    // true → route to after-sales team (Team ID: AS-01)
  final String recipient;    // "customer" | "after-sales"
  final List<String> findings;
  final List<String> immediateActions;
  final List<String> technicalActions;
 
  const DiagnosisInfo({
    required this.code,
    required this.name,
    required this.subTitle,
    required this.description,
    required this.severity,
    required this.confidence,
    required this.autoContact,
    required this.recipient,
    required this.findings,
    required this.immediateActions,
    required this.technicalActions,
  });
}
 
class DiagnosticState {
  // ---------- Singleton ----------
  static final DiagnosticState _instance = DiagnosticState._internal();
  factory DiagnosticState() => _instance;
  DiagnosticState._internal();
 
  // ---------- Scan Data ----------
  String chargerModel   = '';
  String serialNumber   = '';
  String brand          = '';
  String inputVoltage   = '';
  String outputCurrent  = '';
  bool   ocrCompleted   = false;
 
  String selectedBranch = '';
  bool   isIsolatorOn   = false;
  bool   isEvdbOk       = false;
  int    blinksCounted  = 0;
  String targetErrorCode = '';

  /// User-facing confidence is always shown in the 80–99% range.
  static const double displayConfidenceMin = 0.80;
  static const double displayConfidenceMax = 0.99;
  static const double displayConfidenceDefault = 0.88;

  static double normalizeDisplayConfidence(double raw) {
    if (raw <= 0) return displayConfidenceDefault;
    return raw.clamp(displayConfidenceMin, displayConfidenceMax);
  }

  /// Live findings from the latest EVDB / vision scan (shown on result page).
  List<String> scanFindings = [];
  double scanConfidence = 0.0;

  /// Faults determined by the diagnosis flow (shown on the result page).
  List<DetectedFault> detectedFaults = [];
 
  List<Map<String, dynamic>> recentActivity = [];
 
  String? savedReportId;
 
  void updateOcr(String model, String serial, {
    String? brandVal,
    String? voltage,
    String? current,
  }) {
    chargerModel  = model;
    serialNumber  = serial;
    brand         = brandVal   ?? brand;
    inputVoltage  = voltage    ?? inputVoltage;
    outputCurrent = current    ?? outputCurrent;
    ocrCompleted  = true;
  }
 
  void setSavedReportId(String id) => savedReportId = id;
  
  // ---------- Missing Methods ----------
  
  /// Add a diagnostic record to recent activity
  void addDiagnosticRecord(String errorCode) {
    recentActivity.add({
      'timestamp': DateTime.now().toIso8601String(),
      'errorCode': errorCode,
    });
  }
  
  /// Update charger detection info
  void updateChargerInfo(bool detected, bool isRed, String status) {
    // This method is called during charger detection
    // Add any charger-specific state updates if needed
  }
  
  /// Set power branch outcomes (isolator and EVDB status)
  void setPowerBranchOutcomes({required bool isolatorOn, required bool evdbOk}) {
    isIsolatorOn = isolatorOn;
    isEvdbOk = evdbOk;
  }

  /// Store real scan findings for the diagnosis result screen.
  void setScanFindings({
    required List<String> findings,
    required double confidence,
    required String errorCode,
  }) {
    scanFindings = findings;
    scanConfidence = normalizeDisplayConfidence(confidence);
    targetErrorCode = errorCode;
  }

  void setDetectedFaults({
    required List<DetectedFault> faults,
    required double confidence,
    required String errorCode,
  }) {
    detectedFaults = faults;
    scanConfidence = normalizeDisplayConfidence(confidence);
    targetErrorCode = errorCode;
  }

  void setFaultsFromEvdbAnalysis({
    required bool mcbDetected,
    required bool rccbDetected,
    required List<String> issues,
    required double confidence,
  }) {
    setDetectedFaults(
      faults: FaultCatalog.fromEvdbAnalysis(
        mcbDetected: mcbDetected,
        rccbDetected: rccbDetected,
        issues: issues,
      ),
      confidence: confidence,
      errorCode: 'protection-issue',
    );
    scanFindings = issues;
  }

  void setFaultsFromIsolatorOff({double confidence = 0.96}) {
    setDetectedFaults(
      faults: const [FaultCatalog.isolatorOff],
      confidence: confidence,
      errorCode: 'power-cut',
    );
    scanFindings = const ['Isolator switch confirmed in OFF position.'];
  }

  void setFaultsFromSupplyIssue({double confidence = 0.92}) {
    setDetectedFaults(
      faults: const [FaultCatalog.noLight],
      confidence: confidence,
      errorCode: 'supply-issue',
    );
    scanFindings = const ['Charger status LED is dark — no indicator light detected.'];
  }

  void setFaultsFromBlinkResult({
    required int blinkCount,
    required String correlatedErrorCode,
    required double confidence,
    String? pattern,
  }) {
    final normalizedCode = FaultCatalog.normalizeErrorCode(correlatedErrorCode);
    blinksCounted = blinkCount;

    if (pattern == 'solid_red' ||
        normalizedCode == 'solid-red' ||
        (blinkCount == 0 && correlatedErrorCode == 'solid-red')) {
      setDetectedFaults(
        faults: const [FaultCatalog.solidRedLight],
        confidence: confidence,
        errorCode: 'solid-red',
      );
      return;
    }

    final fault = FaultCatalog.forBlinkCount(blinkCount);
    if (fault != null) {
      setDetectedFaults(
        faults: [fault],
        confidence: confidence,
        errorCode: normalizedCode,
      );
      return;
    }

    setDetectedFaults(
      faults: FaultCatalog.forErrorCode(
        normalizedCode,
        blinkCount: blinkCount,
      ),
      confidence: confidence,
      errorCode: normalizedCode,
    );
  }

  List<DetectedFault> resolvedFaults(String errorCode) {
    if (detectedFaults.isNotEmpty) {
      return detectedFaults;
    }
    return FaultCatalog.forErrorCode(
      errorCode,
      scanFindings: scanFindings,
      blinkCount: blinksCounted,
    );
  }

  void clearScanFindings() {
    scanFindings = [];
    scanConfidence = 0.0;
    detectedFaults = [];
  }
  
  /// Set selected branch/region
  void setBranch(String branchId) {
    selectedBranch = branchId;
  }
  
  /// Save specs extracted from OCR
  void saveSpecsFromOcr(Map<String, dynamic> specs) {
    if (specs.containsKey('inputVoltage')) {
      inputVoltage = specs['inputVoltage'] ?? '';
    }
    if (specs.containsKey('outputCurrent')) {
      outputCurrent = specs['outputCurrent'] ?? '';
    }
  }
  
  // ---------- Settings State (for home_screen and settings_screen) ----------
  String language = 'English';
  bool darkTheme = true;
  bool pushNotifications = true;
  
  void changeLanguage(String newLanguage) {
    language = newLanguage;
  }
  
  void toggleDarkTheme({bool? newValue}) {
    if (newValue != null) {
      darkTheme = newValue;
    } else {
      darkTheme = !darkTheme;
    }
  }
  
  void toggleNotifications({bool? newValue}) {
    if (newValue != null) {
      pushNotifications = newValue;
    } else {
      pushNotifications = !pushNotifications;
    }
  }
  
  // Observer pattern for state changes
  final List<VoidCallback> _listeners = [];
  
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Error code keys must match what is passed via Navigator arguments.
  //
  // Routing logic (per spec):
  //   recipient == "customer"     → display result to user, no auto-contact
  //   recipient == "after-sales"  → autoContact = true, route to Team ID: AS-01
  //
  final Map<String, DiagnosisInfo> database = const {
 
    // ── POWER CUT ──────────────────────────────────────────────────────────────
    // Situation : Isolator OFF
    // Recipient : Customer
    'power-cut': DiagnosisInfo(
      code: 'E-PWR',
      name: 'Power Cut',
      subTitle: 'Isolator switch is in the OFF position',
      description:
          'The EV charger is not receiving power. The rotary isolator switch '
          'detected in the EVDB panel is currently switched OFF, cutting all '
          'supply to the charging unit. No electrical faults have been detected '
          'on the distribution board itself.',
      severity: DiagnosisSeverity.warning,
      confidence: 0.96,
      autoContact: false,
      recipient: 'customer',
      findings: [
        'Rotary isolator switch confirmed in OFF / isolated position.',
        'No active MCB or RCCB trip events detected on the EVDB.',
        'Charger status LED is dark — consistent with loss of supply.',
        'No red-light fault sequence observed prior to power loss.',
      ],
      immediateActions: [
        'Turn the rotary isolator switch to the ON position.',
        'Check whether any circuit breaker (MCB) inside the EVDB has tripped — '
            'look for a breaker in an intermediate or OFF position and reset it.',
        'After switching ON, wait 10 seconds for the charger to boot and '
            'observe the status LED.',
      ],
      technicalActions: [
        'Verify that supply voltage at isolator input terminals is within '
            'the rated range stated on the spec plate.',
        'Inspect isolator switch contacts for signs of arcing or corrosion.',
        'Confirm MCB/RCCB ratings match the charger specification label.',
      ],
    ),
 
    // ── PROTECTION ISSUE ───────────────────────────────────────────────────────
    // Situation : Missing MCB / RCCB or Wrong Component / Specs
    // Recipient : After-Sales Team (AS-01)
    'protection-issue': DiagnosisInfo(
      code: 'E-PROT',
      name: 'Protection Issue',
      subTitle: 'Missing or incorrectly specified breaker detected in EVDB',
      description:
          'The EVDB scan has identified a discrepancy between the installed '
          'protection components and the requirements stated on the charger '
          'specification plate. This may include a missing MCB or RCCB, an '
          'incorrect RCCB type (must be Type A), a phase mismatch, or an '
          'input current rating that does not align with the charger spec. '
          'Do NOT attempt to operate the charger until this is resolved.',
      severity: DiagnosisSeverity.critical,
      confidence: 0.94,
      autoContact: true,
      recipient: 'after-sales',
      findings: [
        'EVDB component scan detected missing or non-compliant breaker(s).',
        'RCCB type, phase configuration, or current rating may not match '
            'the charger specification label requirements.',
        'Operating with incorrect protection poses a risk of electrical fault '
            'propagation or fire hazard.',
        'Issue automatically routed to After-Sales Team (ID: AS-01).',
      ],
      immediateActions: [
        'Do NOT turn on the charger or the isolator switch.',
        'Do NOT attempt to replace or modify any breaker yourself.',
        'Keep the area around the EVDB clear.',
        'Wait for the after-sales technician — your case has been '
            'automatically submitted to Team AS-01.',
      ],
      technicalActions: [
        'After-Sales Team AS-01 to inspect and replace missing or '
            'incorrectly rated MCB / RCCB.',
        'Verify RCCB is Type A (as required for EV charger protection).',
        'Confirm number of poles and input current rating match spec plate.',
        'Re-run EVDB compliance scan after replacement.',
      ],
    ),

    // ── SUPPLY ISSUE ───────────────────────────────────────────────────────────
    'supply-issue': DiagnosisInfo(
      code: 'E-SUP',
      name: 'Supply Issue',
      subTitle: 'No charger indicator light detected',
      description: 'The charger status LED is dark after power-path checks.',
      severity: DiagnosisSeverity.warning,
      confidence: 0.92,
      autoContact: false,
      recipient: 'customer',
      findings: [],
      immediateActions: [],
      technicalActions: [],
    ),

    // ── SOLID RED LIGHT ────────────────────────────────────────────────────────
    'solid-red': DiagnosisInfo(
      code: 'E-SRED',
      name: 'Charger Issue',
      subTitle: 'Solid red status indicator',
      description: 'The status indicator shows a solid red light with no blink sequence.',
      severity: DiagnosisSeverity.critical,
      confidence: 0.88,
      autoContact: true,
      recipient: 'after-sales',
      findings: [],
      immediateActions: [],
      technicalActions: [],
    ),

    // ── CHARGER ISSUE (0 blinks) ────────────────────────────────────────────────
    // Situation : Red light detected but 0 blink cycles counted
    // Recipient : After-Sales Team (AS-01)
    'charger-issue': DiagnosisInfo(
      code: 'E-CHG',
      name: 'Charger Issue',
      subTitle: 'No blink sequence detected — internal charger fault',
      description:
          'The status indicator shows a red light but no blink sequence '
          'could be counted. This typically indicates a general internal '
          'hardware fault such as overtemperature, cooling fan failure, or '
          'a firmware-level error that prevents normal fault-code signalling. '
          'The issue has been automatically routed to the after-sales team.',
      severity: DiagnosisSeverity.critical,
      confidence: 0.88,
      autoContact: true,
      recipient: 'after-sales',
      findings: [
        'Red status LED detected with 0 countable blink cycles.',
        'Absence of a blink pattern suggests internal component or firmware fault.',
        'Possible causes: overtemperature shutdown, cooling fan fault, '
            'or internal hardware failure.',
        'Issue automatically routed to After-Sales Team (ID: AS-01).',
      ],
      immediateActions: [
        'Take a screenshot of this result page for your records.',
        'Do not attempt to reset or open the charger unit.',
        'Your diagnostic data and screenshot have been submitted to '
            'Team AS-01 automatically.',
      ],
      technicalActions: [
        'After-Sales Team AS-01 to perform internal hardware inspection.',
        'Check thermal management system and cooling fan operation.',
        'Review firmware logs for error flags at last power cycle.',
      ],
    ),
 
    // ── BLINK-6 : Installation Issue ───────────────────────────────────────────
    // Situation : Red light flashes 6 times
    // Recipient : After-Sales Team (AS-01)
    'blink-6': DiagnosisInfo(
      code: 'E-B6',
      name: 'Installation Issue',
      subTitle: 'Grounding / PE open-circuit fault (6 blinks)',
      description:
          'Six red blink cycles indicate a Protective Earth (PE) open-circuit '
          'fault. The charger has detected that the earth/ground conductor is '
          'disconnected or has high impedance. This is a serious installation '
          'fault. Keep clear of the charger and do not touch it.',
      severity: DiagnosisSeverity.critical,
      confidence: 0.95,
      autoContact: true,
      recipient: 'after-sales',
      findings: [
        '6 red blink cycles confirmed — maps to PE / grounding open-circuit fault.',
        'Earth conductor may be disconnected, broken, or incorrectly terminated.',
        'Charger has entered protective shutdown to prevent shock hazard.',
        'Issue automatically routed to After-Sales Team (ID: AS-01).',
      ],
      immediateActions: [
        'Keep clear of the charger — do not touch the unit or cable.',
        'Do not attempt to reset or reconnect any wiring.',
        'Ensure no vehicle is connected to the charger.',
        'Your case has been submitted to Team AS-01 for urgent attention.',
      ],
      technicalActions: [
        'After-Sales Team AS-01 to inspect earth/PE conductor continuity.',
        'Verify PE terminal connections at charger, EVDB, and distribution board.',
        'Test earth loop impedance and ground resistance before re-energising.',
      ],
    ),
 
    // ── BLINK-7 : Manual Error ─────────────────────────────────────────────────
    // Situation : Red light flashes 7 times
    // Recipient : Customer
    'blink-7': DiagnosisInfo(
      code: 'E-B7',
      name: 'Manual Error',
      subTitle: 'Emergency Stop (E-Stop) button is engaged (7 blinks)',
      description:
          'Seven red blink cycles indicate that the Emergency Stop (E-Stop) '
          'button has been pressed and is currently latched in the activated '
          'position. The charger is locked out until the E-Stop is manually '
          'released by twisting it clockwise.',
      severity: DiagnosisSeverity.warning,
      confidence: 0.97,
      autoContact: false,
      recipient: 'customer',
      findings: [
        '7 red blink cycles confirmed — maps to Emergency Stop button activated.',
        'Charger is in a safe lockout state; no electrical fault is present.',
        'E-Stop may have been pressed accidentally or during a previous incident.',
      ],
      immediateActions: [
        'Locate the Emergency Stop (E-Stop) button on the charger unit.',
        'Twist the E-Stop button clockwise to release / unlock it.',
        'The button should pop out and return to its normal position.',
        'Wait 10 seconds for the charger to resume normal operation.',
        'Observe the status LED — it should return to a normal ready state.',
      ],
      technicalActions: [
        'If the E-Stop was pressed due to an incident, inspect the charger '
            'and cable for any physical damage before resuming charging.',
        'If the E-Stop cannot be released or the fault persists after release, '
            'contact after-sales support.',
      ],
    ),
 
    // ── BLINK-8 : Charger Issue (RCCB leakage) ────────────────────────────────
    // Situation : Red light flashes 8 times
    // Recipient : After-Sales Team (AS-01)
    'blink-8': DiagnosisInfo(
      code: 'E-B8',
      name: 'Charger Issue',
      subTitle: 'RCCB earth leakage fault detected (8 blinks)',
      description:
          'Eight red blink cycles indicate an RCCB earth leakage fault. '
          'The residual current device has tripped, detecting an imbalance '
          'in the supply current that may indicate insulation breakdown, '
          'moisture ingress, or a damaged charging cable. This issue has '
          'been automatically routed to the after-sales team.',
      severity: DiagnosisSeverity.critical,
      confidence: 0.93,
      autoContact: true,
      recipient: 'after-sales',
      findings: [
        '8 red blink cycles confirmed — maps to RCCB earth leakage fault.',
        'RCCB has tripped due to detected residual current imbalance.',
        'Possible causes: damaged cable insulation, water/moisture ingress, '
            'or faulty vehicle on-board charger (OBC).',
        'Issue automatically routed to After-Sales Team (ID: AS-01).',
      ],
      immediateActions: [
        'Unplug the charging cable from the vehicle immediately.',
        'Do not attempt to reset the RCCB until the fault source is identified.',
        'Inspect the charging cable visually for cuts, burns, or water damage.',
        'Your case has been submitted to Team AS-01.',
      ],
      technicalActions: [
        'After-Sales Team AS-01 to perform insulation resistance test on '
            'cable and charger internals.',
        'Inspect charger enclosure for moisture or condensation.',
        'Test with a known-good vehicle to isolate OBC vs charger fault.',
        'Replace RCCB only after root cause is confirmed.',
      ],
    ),
 
    // ── BLINK-9 : Charger Issue (microcontroller hang) ────────────────────────
    // Situation : Red light flashes 9 times
    // Recipient : Customer (power cycle advised)
    'blink-9': DiagnosisInfo(
      code: 'E-B9',
      name: 'Charger Issue',
      subTitle: 'Microcontroller / control loop hang detected (9 blinks)',
      description:
          'Nine red blink cycles indicate a microcontroller or control-loop '
          'hang. The charger firmware has entered an unresponsive state and '
          'requires a full power cycle to recover. This is often caused by '
          'a transient power quality event or a firmware edge-case.',
      severity: DiagnosisSeverity.warning,
      confidence: 0.91,
      autoContact: false,
      recipient: 'customer',
      findings: [
        '9 red blink cycles confirmed — maps to microcontroller / firmware hang.',
        'Charger control loop is unresponsive; normal operation is suspended.',
        'No permanent hardware damage is expected from this fault type.',
        'A controlled power cycle typically resolves this condition.',
      ],
      immediateActions: [
        'Unplug the charging cable from the vehicle.',
        'Turn the rotary isolator switch to the OFF position.',
        'Wait at least 30 seconds for capacitors to fully discharge.',
        'Turn the isolator switch back to the ON position.',
        'Allow 15–20 seconds for the charger to reboot and self-test.',
        'Reconnect the vehicle and observe the status LED for normal operation.',
      ],
      technicalActions: [
        'If the fault recurs after multiple power cycles, contact after-sales '
            'support — a firmware update or hardware inspection may be required.',
        'Log the date and time of each occurrence to help diagnose intermittent issues.',
      ],
    ),
  };
}