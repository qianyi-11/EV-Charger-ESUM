/**
 * EVDB compliance analyzer — YOLO component detection + charger spec validation.
 * Spec validation uses spec-plate voltage only (phase count). No breaker amp OCR.
 */

function normalizeClass(className) {
  return (className || '').toLowerCase().replace(/\s+/g, '_');
}

function isMcbClass(className) {
  const name = normalizeClass(className);
  return name.includes('mcb') && !name.includes('rccb');
}

function isRccbClass(className) {
  const name = normalizeClass(className);
  return name.includes('rccb');
}

function isTypeAClass(className) {
  const name = normalizeClass(className);
  return name.includes('type_a') || name.includes('typea') || name === 'type_a_symbol';
}

function bestDetection(detections, matcher) {
  if (!Array.isArray(detections)) return null;
  const matches = detections.filter((d) => matcher(d.class));
  if (!matches.length) return null;
  return matches.reduce((a, b) => ((b.confidence ?? 0) > (a.confidence ?? 0) ? b : a));
}

/** Width/height ratio for a YOLO box. */
export function boxAspectRatio(box) {
  if (!Array.isArray(box) || box.length !== 4) return null;
  const [x1, y1, x2, y2] = box.map(Number);
  const width = Math.max(x2 - x1, 1);
  const height = Math.max(y2 - y1, 1);
  return width / height;
}

/**
 * Estimate DIN pole/module count from bbox aspect ratio.
 * Portrait EVDB photos: 1P ~0.15–0.33, 2P ~0.33–0.57, 3P ~0.57–0.88, 4P ~0.88+
 * (Old logic used ratio >= 1.35 for 3-phase, which never triggers on typical photos.)
 */
export function inferPoleCountFromBox(box) {
  const ratio = boxAspectRatio(box);
  if (ratio == null) return null;
  if (ratio < 0.34) return 1;
  if (ratio < 0.58) return 2;
  if (ratio < 0.88) return 3;
  return 4;
}

/** Map physical pole count to supply phase: 1–2P = single-phase, 3–4P = three-phase. */
export function supplyPhaseFromPoleCount(poleCount) {
  if (poleCount == null) return null;
  return poleCount >= 3 ? 3 : 1;
}

/** Backward-compatible helper used by tests and API fields. */
export function inferPhaseFromBox(box) {
  return supplyPhaseFromPoleCount(inferPoleCountFromBox(box));
}

export function parseExpectedPhase(inputVoltage) {
  if (!inputVoltage) return null;
  const digits = String(inputVoltage).match(/\d+/g);
  if (!digits?.length) return null;
  const volts = parseInt(digits[0], 10);
  if ([230, 240].includes(volts)) return 1;
  if ([400, 410].includes(volts)) return 3;
  if (volts >= 380) return 3;
  if (volts <= 250) return 1;
  return null;
}

/** 230V single-phase allows 1P/2P breakers; 400V three-phase requires 3P+. */
export function isPoleCountCompatible(poleCount, expectedSupplyPhase) {
  if (poleCount == null || expectedSupplyPhase == null) return false;
  if (expectedSupplyPhase === 1) return poleCount <= 2;
  if (expectedSupplyPhase === 3) return poleCount >= 3;
  return false;
}

function describePoleMismatch(component, poleCount, ratio, expectedPhase, inputVoltage) {
  const supplyPhase = supplyPhaseFromPoleCount(poleCount);
  const ratioText = ratio != null ? ratio.toFixed(2) : 'n/a';
  return (
    `${component} phase mismatch: estimated ${poleCount}-pole (${supplyPhase}-phase supply, ` +
    `box ratio ${ratioText}), spec requires ${expectedPhase}-phase (${inputVoltage}).`
  );
}

/**
 * @param {object} params
 * @param {Array} params.detections - YOLO detections
 * @param {object} params.specsContext - { inputVoltage }
 */
export function analyzeEvdbCompliance({ detections, specsContext = {} }) {
  const { inputVoltage } = specsContext;
  const issues = [];

  const mcbDet = bestDetection(detections, isMcbClass);
  const rccbDet = bestDetection(detections, isRccbClass);
  const typeADet = bestDetection(detections, isTypeAClass);

  const mcbDetected = mcbDet !== null;
  const rccbDetected = rccbDet !== null;
  const typeADetected = typeADet !== null;

  if (!mcbDetected) {
    issues.push('MCB missing — no MCB detected in EVDB image.');
  }
  if (!rccbDetected) {
    issues.push('RCCB missing — no RCCB detected in EVDB image.');
  }

  const expectedPhase = parseExpectedPhase(inputVoltage);
  const mcbPoles = mcbDet ? inferPoleCountFromBox(mcbDet.box) : null;
  const rccbPoles = rccbDet ? inferPoleCountFromBox(rccbDet.box) : null;
  const mcbRatio = mcbDet ? boxAspectRatio(mcbDet.box) : null;
  const rccbRatio = rccbDet ? boxAspectRatio(rccbDet.box) : null;
  const mcbPhase = supplyPhaseFromPoleCount(mcbPoles);
  const rccbPhase = supplyPhaseFromPoleCount(rccbPoles);

  if (!mcbDetected || !rccbDetected) {
    return buildResult({
      issues,
      mcbDetected,
      rccbDetected,
      typeADetected,
      mcbPhase,
      rccbPhase,
      mcbPoles,
      rccbPoles,
      mcbRatio,
      rccbRatio,
      expectedPhase,
      inputVoltage,
      isCompliant: false,
      retakeRequired: false,
    });
  }

  if (!inputVoltage) {
    issues.push('Charger spec plate voltage not available — cannot validate EVDB phase against spec.');
    return buildResult({
      issues,
      mcbDetected,
      rccbDetected,
      typeADetected,
      mcbPhase,
      rccbPhase,
      mcbPoles,
      rccbPoles,
      mcbRatio,
      rccbRatio,
      expectedPhase,
      inputVoltage,
      isCompliant: false,
      retakeRequired: true,
      retakeReason: 'Spec plate voltage missing. Complete OCR scan first, or retake a clearer EVDB photo.',
    });
  }

  if (expectedPhase === null) {
    issues.push(`Cannot determine required phase from spec voltage: ${inputVoltage}`);
    return buildResult({
      issues,
      mcbDetected,
      rccbDetected,
      typeADetected,
      mcbPhase,
      rccbPhase,
      mcbPoles,
      rccbPoles,
      mcbRatio,
      rccbRatio,
      expectedPhase,
      inputVoltage,
      isCompliant: false,
      retakeRequired: true,
      retakeReason: 'Spec plate voltage is unclear. Retake EVDB photo after confirming spec plate OCR.',
    });
  }

  if (mcbPoles == null || !isPoleCountCompatible(mcbPoles, expectedPhase)) {
    issues.push(
      describePoleMismatch('MCB', mcbPoles ?? 0, mcbRatio, expectedPhase, inputVoltage),
    );
  }
  if (rccbPoles == null || !isPoleCountCompatible(rccbPoles, expectedPhase)) {
    issues.push(
      describePoleMismatch('RCCB', rccbPoles ?? 0, rccbRatio, expectedPhase, inputVoltage),
    );
  }

  if (!typeADetected) {
    issues.push('Type A symbol not detected on RCCB — EV charger requires Type A RCCB.');
  }

  const isCompliant = issues.length === 0;

  return buildResult({
    issues,
    mcbDetected,
    rccbDetected,
    typeADetected,
    mcbPhase,
    rccbPhase,
    mcbPoles,
    rccbPoles,
    mcbRatio,
    rccbRatio,
    expectedPhase,
    inputVoltage,
    isCompliant,
    retakeRequired: false,
  });
}

function buildResult(fields) {
  const {
    issues,
    isCompliant,
    retakeRequired = false,
    retakeReason = null,
    mcbDetected,
    rccbDetected,
    typeADetected,
    mcbPhase,
    rccbPhase,
    mcbPoles,
    rccbPoles,
    mcbRatio,
    rccbRatio,
    expectedPhase,
    inputVoltage,
  } = fields;

  const errorCode = isCompliant ? null : 'protection-issue';
  const faultType = isCompliant ? null : 'Protection Issue';

  return {
    success: true,
    isCompliant,
    retakeRequired,
    retakeReason,
    errorCode,
    faultType,
    issues,
    mcbDetected,
    rccbDetected,
    typeADetected,
    mcbPhase,
    rccbPhase,
    mcbPoles,
    rccbPoles,
    mcbRatio,
    rccbRatio,
    expectedPhase,
    inputVoltage: inputVoltage ?? null,
    confidence: isCompliant ? 0.95 : Math.max(0.75, 0.95 - issues.length * 0.05),
    errorMessage: isCompliant
      ? ''
      : retakeRequired
        ? (retakeReason || issues.join(' '))
        : issues.join(' '),
  };
}
