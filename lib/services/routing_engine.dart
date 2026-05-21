enum FaultType {
  powerCut,
  protectionIssue,
  chargerIssue,
  installationIssue,
  manualError,
  unknown
}

enum ActionDirective {
  showCustomerPrompt,
  routeToAfterSales
}

class RoutingDecision {
  final FaultType faultType;
  final ActionDirective directive;
  final String actionDescription;
  final String errorCode;

  RoutingDecision({
    required this.faultType,
    required this.directive,
    required this.actionDescription,
    required this.errorCode,
  });

  bool get routeToAfterSales => directive == ActionDirective.routeToAfterSales;
}

class RoutingEngine {
  /// Evaluates the sequence of events to determine the fault
  RoutingDecision evaluateFault({
    bool isChargerDead = false,
    bool isIsolatorOff = false,
    bool isMcbMissingOrWrong = false,
    bool isSolidRedLight = false,
    int flashCount = 0,
  }) {
    // Branch 1 logic
    if (isChargerDead) {
      if (isIsolatorOff) {
        return RoutingDecision(
          faultType: FaultType.powerCut,
          directive: ActionDirective.showCustomerPrompt,
          actionDescription: "Advise customer to turn ON Isolator and check EVDB breakers.",
          errorCode: "power-cut",
        );
      }
      if (isMcbMissingOrWrong) {
        return RoutingDecision(
          faultType: FaultType.protectionIssue,
          directive: ActionDirective.routeToAfterSales,
          actionDescription: "Route to after-sales to repair/replace missing or incorrect breakers.",
          errorCode: "protection-issue",
        );
      }
    }

    // Branch 2 logic
    if (isSolidRedLight) {
      return RoutingDecision(
        faultType: FaultType.chargerIssue,
        directive: ActionDirective.routeToAfterSales,
        actionDescription: "Advise user to screenshot and route issue to after-sales team.",
        errorCode: "charger-issue",
      );
    }

    if (flashCount == 6) {
      return RoutingDecision(
        faultType: FaultType.installationIssue,
        directive: ActionDirective.routeToAfterSales,
        actionDescription: "Route issue to after-sales team.",
        errorCode: "blink-6",
      );
    } else if (flashCount == 7) {
      return RoutingDecision(
        faultType: FaultType.manualError,
        directive: ActionDirective.showCustomerPrompt,
        actionDescription: "Advise customer to release EmergencyStop Button.",
        errorCode: "blink-7",
      );
    } else if (flashCount == 8) {
      return RoutingDecision(
        faultType: FaultType.chargerIssue,
        directive: ActionDirective.routeToAfterSales,
        actionDescription: "Route issue to after-sales team.",
        errorCode: "blink-8",
      );
    } else if (flashCount == 9) {
      return RoutingDecision(
        faultType: FaultType.chargerIssue,
        directive: ActionDirective.showCustomerPrompt,
        actionDescription: "Advise customer to shut down charger a while & restart.",
        errorCode: "blink-9",
      );
    }

    return RoutingDecision(
      faultType: FaultType.unknown,
      directive: ActionDirective.showCustomerPrompt,
      actionDescription: "Unable to determine fault automatically. Tap [Start Diagnosis].",
      errorCode: "unknown",
    );
  }
}
