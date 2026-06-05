/**
 * EVDB compliance analyzer — YOLO component detection + charger spec validation.
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

/** Infer 1-pole vs 3-pole from YOLO box aspect ratio (3-pole DIN breakers are wider). */
export function inferPhaseFromBox(box) {
  if (!Array.isArray(box) || box.length !== 4) return null;
  const [x1, y1, x2, y2] = box.map(Number);
  const width = Math.max(x2 - x1, 1);
  const height = Math.max(y2 - y1, 1);
  const ratio = width / height;
  return ratio >= 1.35 ? 3 : 1;
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

export function parseSpecCurrentAmps(outputCurrent) {
  if (!outputCurrent) return null;
  const match = String(outputCurrent).match(/(\d+)\s*A/i);
  return match ? parseInt(match[1], 10) : null;
}

export function parseBreakerAmps(label) {
  if (!label) return null;
  const match = String(label).match(/(\d+)\s*A/i);
  return match ? parseInt(match[1], 10) : null;
}

/**
 * @param {object} params
 * @param {Array} params.detections - YOLO detections
 * @param {object} params.specsContext - { inputVoltage, outputCurrent }
 * @param {object|null} params.ocrResult - optional Gemini OCR on EVDB image
 */
export function analyzeEvdbCompliance({ detections, specsContext = {}, ocrResult = null }) {
  const { inputVoltage, outputCurrent } = specsContext;
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
  const specCurrent = parseSpecCurrentAmps(outputCurrent);

  let mcbPhase = mcbDet ? inferPhaseFromBox(mcbDet.box) : null;
  let rccbPhase = rccbDet ? inferPhaseFromBox(rccbDet.box) : null;

  let detectedMcbRating = ocrResult?.detectedMcbRating ?? 'Unknown';
  let detectedRccbRating = ocrResult?.detectedRccbRating ?? 'Unknown';
  const rccbAmps = parseBreakerAmps(detectedRccbRating);
  const mcbAmps = parseBreakerAmps(detectedMcbRating);

  // Missing breakers → protection issue immediately
  if (!mcbDetected || !rccbDetected) {
    return buildResult({
      issues,
      mcbDetected,
      rccbDetected,
      typeADetected,
      mcbPhase,
      rccbPhase,
      expectedPhase,
      specCurrent,
      detectedMcbRating,
      detectedRccbRating,
      isCompliant: false,
      retakeRequired: false,
    });
  }

  // Both present — spec validation
  if (!inputVoltage || !outputCurrent) {
    issues.push('Charger spec plate voltage/current not available — cannot validate EVDB against spec.');
    return buildResult({
      issues,
      mcbDetected,
      rccbDetected,
      typeADetected,
      mcbPhase,
      rccbPhase,
      expectedPhase,
      specCurrent,
      detectedMcbRating,
      detectedRccbRating,
      isCompliant: false,
      retakeRequired: true,
      retakeReason: 'Spec plate data missing. Complete OCR scan first, or retake a clearer EVDB photo.',
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
      expectedPhase,
      specCurrent,
      detectedMcbRating,
      detectedRccbRating,
      isCompliant: false,
      retakeRequired: true,
      retakeReason: 'Spec plate voltage is unclear. Retake EVDB photo after confirming spec plate OCR.',
    });
  }

  if (mcbPhase !== expectedPhase) {
    issues.push(
      `MCB phase mismatch: detected ${mcbPhase}-phase, spec requires ${expectedPhase}-phase (${inputVoltage}).`,
    );
  }
  if (rccbPhase !== expectedPhase) {
    issues.push(
      `RCCB phase mismatch: detected ${rccbPhase}-phase, spec requires ${expectedPhase}-phase (${inputVoltage}).`,
    );
  }

  // Type A symbol on RCCB
  if (!typeADetected) {
    issues.push('Type A symbol not detected on RCCB — EV charger requires Type A RCCB.');
  }

  // Current rule: spec 32A → RCCB should read 40A
  if (specCurrent === 32) {
    if (rccbAmps === null) {
      issues.push('Could not read RCCB current rating from EVDB image (expected 40A for 32A charger spec).');
      return buildResult({
        issues,
        mcbDetected,
        rccbDetected,
        typeADetected,
        mcbPhase,
        rccbPhase,
        expectedPhase,
        specCurrent,
        expectedRccbAmps: 40,
        detectedMcbRating,
        detectedRccbRating,
        isCompliant: false,
        retakeRequired: true,
        retakeReason: 'EVDB photo is not clear enough to read RCCB rating. Please retake a closer, sharper photo.',
      });
    }
    if (rccbAmps !== 40) {
      issues.push(`RCCB rating mismatch: read ${rccbAmps}A, expected 40A for 32A charger specification.`);
    }
  }

  const isCompliant = issues.length === 0;

  return buildResult({
    issues,
    mcbDetected,
    rccbDetected,
    typeADetected,
    mcbPhase,
    rccbPhase,
    expectedPhase,
    specCurrent,
    expectedRccbAmps: specCurrent === 32 ? 40 : null,
    detectedMcbRating: mcbAmps ? `${mcbAmps}A` : detectedMcbRating,
    detectedRccbRating: rccbAmps ? `${rccbAmps}A` : detectedRccbRating,
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
    expectedPhase,
    specCurrent,
    expectedRccbAmps,
    detectedMcbRating,
    detectedRccbRating,
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
    expectedPhase,
    specCurrent,
    expectedRccbAmps: expectedRccbAmps ?? null,
    detectedMcbRating,
    detectedRccbRating,
    confidence: isCompliant ? 0.95 : Math.max(0.75, 0.95 - issues.length * 0.05),
    errorMessage: isCompliant
      ? ''
      : retakeRequired
        ? (retakeReason || issues.join(' '))
        : issues.join(' '),
  };
}
