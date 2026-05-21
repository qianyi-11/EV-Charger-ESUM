import 'package:flutter/material.dart';

enum DiagnosisSeverity { critical, warning, success }

class DiagnosisInfo {
  final String code;
  final String name;
  final String subTitle;
  final DiagnosisSeverity severity;
  final bool autoContact;
  final String description;
  final double confidence;
  final List<String> findings;
  final List<String> immediateActions;
  final List<String> technicalActions;

  DiagnosisInfo({
    required this.code,
    required this.name,
    required this.subTitle,
    required this.severity,
    required this.autoContact,
    required this.description,
    required this.confidence,
    required this.findings,
    required this.immediateActions,
    required this.technicalActions,
  });
}

class DiagnosticState extends ChangeNotifier {
  // Singleton Pattern
  static final DiagnosticState _instance = DiagnosticState._internal();
  factory DiagnosticState() => _instance;
  DiagnosticState._internal();

  // OCR Spec Data
  String chargerModel = "Unknown Charger";
  String serialNumber = "Unknown Serial";
  bool ocrCompleted = false;

  // Firestore Sync Data
  String? savedReportId;

  void setSavedReportId(String? reportId) {
    savedReportId = reportId;
    notifyListeners();
  }

  // Branch Selection
  int selectedBranch = 2; // Default to Red Light (Branch 2). 1 = No Light (Branch 1).

  // Power branch state outcomes (injectable for testing)
  bool isIsolatorOn = false;
  bool isEvdbOk = false;

  // Blink branch details
  int blinksCounted = 0;
  String targetErrorCode = "blink-8";

  // System Configuration / Settings
  String language = "English";
  bool darkTheme = true;
  bool pushNotifications = true;
  bool offlineSync = true;

  // Diagnostic Records
  final List<Map<String, dynamic>> recentActivity = [
    {
      "description": "Grounding Fault Detected during startup check",
      "timestamp": "2026-05-20 15:45",
      "status": "critical",
      "code": "blink-6"
    },
    {
      "description": "Emergency Stop Triggered manually by user",
      "timestamp": "2026-05-20 12:10",
      "status": "warning",
      "code": "blink-7"
    },
    {
      "description": "Power infrastructure normal, Isolator turned ON",
      "timestamp": "2026-05-19 09:30",
      "status": "success",
      "code": "power-cut"
    }
  ];

  // Static Diagnostic Knowledgebase
  final Map<String, DiagnosisInfo> database = {
    "power-cut": DiagnosisInfo(
      code: "PWR-001",
      name: "Isolator Switch is OFF",
      subTitle: "Power Supply Interrupted",
      severity: DiagnosisSeverity.critical,
      autoContact: false,
      description: "The primary power isolation switch is in the OFF position. This has cut off all electrical feed to the vehicle charging system. The EV charger is structurally healthy, but requires direct physical switch reactivation to receive electricity.",
      confidence: 0.99,
      findings: [
        "Isolator switch position visually verified as OFF",
        "Zero electrical current arriving at EV charger terminals",
        "External upstream breakers currently report standard status",
      ],
      immediateActions: [
        "Locate the primary isolator lever beside the charger",
        "Carefully flip the isolator switch toggle to the ON position",
        "Wait 10 seconds for the charger boot sequence to initialize"
      ],
      technicalActions: [
        "If power does not return, inspect the main distribution board breakers",
        "Verify 230V mains voltage is present at the input side of the isolator",
        "Check for mechanical faults in the switch contact terminal blocks"
      ]
    ),
    "protection-issue": DiagnosisInfo(
      code: "MCB-001",
      name: "Wrong Board Specification",
      subTitle: "EVDB Component Anomaly",
      severity: DiagnosisSeverity.critical,
      autoContact: true,
      description: "An incompatible or missing breaker component was detected in the EV Distribution Board (EVDB). Operating the charger under these conditions represents a significant safety hazard, which could lead to fire or severe damage.",
      confidence: 0.94,
      findings: [
        "Incorrect Miniature Circuit Breaker (MCB) capacity rating",
        "Residual Current Circuit Breaker (RCCB) trip test failed",
        "Sub-standard gauge copper wire detected during inspection"
      ],
      immediateActions: [
        "A technician has been automatically contacted to replace the components",
        "DO NOT attempt to reactivate the distribution board breakers",
        "Keep the isolator switch OFF until the technician arrives on site"
      ],
      technicalActions: [
        "Replace the standard MCB with an approved EV-rated Class A Type-A/B RCCB",
        "Ensure all wires conform strictly to 32A capacity standard regulations",
        "Perform full earth loop resistance measurements"
      ]
    ),
    "blink-6": DiagnosisInfo(
      code: "ERR-006",
      name: "Termination / Grounding Issue",
      subTitle: "Earth Connection Missing",
      severity: DiagnosisSeverity.critical,
      autoContact: true,
      description: "The charger has detected a critical grounding fault. The ground path resistance is too high or the grounding conductor is disconnected entirely. Standard electric vehicles will block charging under this condition to prevent high chassis voltages.",
      confidence: 0.97,
      findings: [
        "PE (Protective Earth) terminal block reports open circuit resistance",
        "Stray neutral-to-earth potential exceeds safe operating threshold (>10V)",
        "Internal monitoring relay has blocked contactor engagement"
      ],
      immediateActions: [
        "An after-sales maintenance team has been notified and dispatched",
        "Disconnect the charging vehicle immediately from the holster",
        "Ensure no active charging sessions are forced via overrides"
      ],
      technicalActions: [
        "Inspect the grounding terminal blocks inside the charger chassis",
        "Measure ground resistance using a dedicated earth resistance tester",
        "Verify correct Neutral-Earth configuration at the primary distribution board"
      ]
    ),
    "blink-7": DiagnosisInfo(
      code: "ERR-007",
      name: "Emergency Stop Activated",
      subTitle: "E-Stop Safety Relay Open",
      severity: DiagnosisSeverity.warning,
      autoContact: true,
      description: "The safety system reports that the Emergency Stop Button has been physically depressed. This immediately cuts current to the main supply relays, isolating the charger output. The system will remain locked until manually reset.",
      confidence: 0.98,
      findings: [
        "E-Stop switch auxiliary dry contacts are currently in open position",
        "Contactor coil is locked out by hardware safety loop",
        "Manual E-stop lock engaged on side of physical housing"
      ],
      immediateActions: [
        "Technician has been alerted. However, you can attempt manual reset",
        "Inspect the physical charger for any active hazard or smoke",
        "Locate the red mushroom E-Stop button on the side panel",
        "Twist the red button clockwise to pop it back out into ready status"
      ],
      technicalActions: [
        "Verify safety loop continuity using a standard digital multimeter",
        "Check for stuck micro-switches or mechanical damage behind the E-Stop cap",
        "Test isolation breaker response to E-stop depress cycles"
      ]
    ),
    "blink-8": DiagnosisInfo(
      code: "ERR-008",
      name: "RCCB Fault / Cable Issue",
      subTitle: "Earth Leakage or Damage Detected",
      severity: DiagnosisSeverity.critical,
      autoContact: true,
      description: "A critical ground fault or leakage current has triggered the internal protective shutdown. This can indicate damage to the charging plug, insulation breakdown in the cable, or moisture inside the coupling head.",
      confidence: 0.96,
      findings: [
        "Ground leakage sensor has registered active fault current (>30mA)",
        "Insulation resistance check yielded low values (<2M Ohm)",
        "Cable temperature probes report normal parameters"
      ],
      immediateActions: [
        "Technician has been automatically notified and is reviewing telemetry",
        "Disconnect the charger plug from the vehicle immediately",
        "Inspect the physical charging cord for cracks, cuts, or heavy abrasions",
        "Store the cable securely to prevent moisture entry into plug contacts"
      ],
      technicalActions: [
        "Measure insulation resistance across all line-to-earth conductors",
        "Replace the primary charging connector cable if physical damage is found",
        "Verify internal ground leakage monitor board is calibrated"
      ]
    ),
    "blink-9": DiagnosisInfo(
      code: "ERR-009",
      name: "System Restart Required",
      subTitle: "Internal Control Loop Hang",
      severity: DiagnosisSeverity.warning,
      autoContact: true,
      description: "The micro-controller has entered a locked state due to an internal firmware crash, or a transient power brownout. The main safety boards are healthy, but a full system reboot is necessary to clear the state and reload configurations.",
      confidence: 0.95,
      findings: [
        "Control board communication timer has expired (watchdog timeout)",
        "Mains frequency fluctuation detected during initialization",
        "Memory allocation fault on controller board"
      ],
      immediateActions: [
        "Technician notified. You can perform a power cycle to resolve",
        "Locate the main power isolator switch or breaker and flip it OFF",
        "Wait at least 30 seconds for the internal capacitors to discharge fully",
        "Flip the switch back ON and monitor the LED indicator boots normally"
      ],
      technicalActions: [
        "Verify supply grid frequency stays within strict 49.5Hz - 50.5Hz range",
        "Connect technician diagnostic kit to review error stack memory dump",
        "Flash the latest system firmware (v2.4.2) to mitigate buffer overruns"
      ]
    ),
    "charger-issue": DiagnosisInfo(
      code: "GEN-001",
      name: "General Charger Fault",
      subTitle: "Hardware Component Anomaly",
      severity: DiagnosisSeverity.warning,
      autoContact: true,
      description: "An unclassified telemetry error has occurred. This could be due to internal cooling fan failure, over-temperature, or sensor calibration degradation. Secure maintenance is required.",
      confidence: 0.90,
      findings: [
        "Internal operating temperature registers near maximum threshold (80°C)",
        "Secondary safety board communications report intermittent packets",
        "General warning active flag set on control register"
      ],
      immediateActions: [
        "Technician has been auto-contacted to check the charger's hardware",
        "Ensure charger casing is not blocked by dirt, debris, or shade covers",
        "Avoid using the charger until system has cooled down and re-assessed"
      ],
      technicalActions: [
        "Verify physical fan operations and intake clearance",
        "Test safety temperature sensor calibration offsets",
        "Check internal DC auxiliary power rail voltages"
      ]
    ),
  };

  void updateOcr(String model, String serial) {
    chargerModel = model;
    serialNumber = serial;
    ocrCompleted = true;
    notifyListeners();
  }

  void resetOcr() {
    chargerModel = "Unknown Charger";
    serialNumber = "Unknown Serial";
    ocrCompleted = false;
    notifyListeners();
  }

  void setBranch(int branch) {
    selectedBranch = branch;
    notifyListeners();
  }

  void setPowerBranchOutcomes({required bool isolatorOn, required bool evdbOk}) {
    isIsolatorOn = isolatorOn;
    isEvdbOk = evdbOk;
    notifyListeners();
  }

  void addDiagnosticRecord(String code) {
    final info = database[code];
    if (info == null) return;
    
    recentActivity.insert(0, {
      "description": "${info.name} - Identified on Charger ${chargerModel != "Unknown Charger" ? chargerModel : 'TWC-Gen3'}",
      "timestamp": "Just Now",
      "status": info.severity == DiagnosisSeverity.critical
          ? "critical"
          : info.severity == DiagnosisSeverity.warning
              ? "warning"
              : "success",
      "code": code,
    });
    notifyListeners();
  }

  void toggleDarkTheme(bool val) {
    darkTheme = val;
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    pushNotifications = val;
    notifyListeners();
  }

  void toggleOfflineSync(bool val) {
    offlineSync = val;
    notifyListeners();
  }

  void changeLanguage(String lang) {
    language = lang;
    notifyListeners();
  }
}
