import express from 'express';
import cors from 'cors';
import multer from 'multer';
import dotenv from 'dotenv';
import {
  processOcr,
  chatAssistant
} from './services/gemini.js';
import { runYoloInference, runIsolatorYoloInference } from './services/yolo.js';
import { runGatewayDetection, runRedViaWorker, warmVisionWorker } from './services/vision_worker.js';
import { analyzeEvdbCompliance } from './services/evdb_analyzer.js';
import { analyzeBlinkingVideo } from './services/blinking_detector.js';

// Load environment variables from .env file
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Enable cross-origin resource sharing so the Flutter mobile client can connect
app.use(cors());
app.use(express.json());

// Set up memory storage for multipart/form-data file uploads
const upload = multer({ storage: multer.memoryStorage() });

// Logger middleware for console diagnostics
app.use((req, res, next) => {
  console.log(`[HTTP Request] ${req.method} ${req.path} - ${new Date().toISOString()}`);
  next();
});

/**
 * 1. POST /api/vision/ocr
 * Spec Plate recognition and text parameter extraction.
 */
app.post('/api/vision/ocr', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }

    // Run YOLO + Gemini OCR in parallel
    const [yoloResult, ocrResult] = await Promise.all([
      runYoloInference(req.file.buffer),
      processOcr(req.file.buffer),
    ]);

    // Extract charger brand from YOLO detections
    const brandClasses = [
      'BMW', 'GWM', 'Proton_eMAS', 'Revo', 'Smart',
      'StarCharge', 'Zeeda_energy', 'iCAUR'
    ];

    let detectedBrand = null;
    if (yoloResult.success && yoloResult.detections?.length) {
      const brandDetection = yoloResult.detections
        .filter(d => brandClasses.includes(d.class))
        .sort((a, b) => b.confidence - a.confidence)[0]; // highest confidence
      
      if (brandDetection) {
        detectedBrand = brandDetection.class.replace(/_/g, ' '); // "Zeeda_energy" → "Zeeda energy"
        console.log(`[OCR Route] YOLO brand detected: ${detectedBrand} (${brandDetection.confidence})`);
      }
    }

    // YOLO brand takes priority over Gemini brand
    const finalBrand = detectedBrand ?? ocrResult.brand ?? 'Unknown';

    console.log('[OCR Result]');
    console.log(`  Brand:          ${finalBrand} (source: ${detectedBrand ? 'YOLO' : 'Gemini'})`);
    console.log(`  Model:          ${ocrResult.modelName}`);
    console.log(`  Serial Number:  ${ocrResult.serialNumber}`);
    console.log(`  Input Voltage:  ${ocrResult.inputVoltage}`);
    console.log(`  Output Current: ${ocrResult.outputCurrent}`);
    console.log(`  Confidence:     ${ocrResult.confidence}`);

    res.json({
      ...ocrResult,
      brand: finalBrand,
      brandSource: detectedBrand ? 'yolo' : 'gemini',
      yoloDetections: yoloResult.detections,
    });

  } catch (error) {
    const message = error?.message || String(error);
    const quotaExceeded =
      message.includes('429') ||
      message.includes('RESOURCE_EXHAUSTED') ||
      message.toLowerCase().includes('quota');
    if (quotaExceeded) {
      return res.status(200).json({
        success: false,
        quotaExceeded: true,
        brand: 'unknown',
        modelName: 'unknown',
        serialNumber: 'unknown',
        inputVoltage: 'unknown',
        outputCurrent: 'unknown',
        reason:
          'Gemini API daily quota exceeded (free tier: 20 requests/day). Wait a minute or upgrade billing.',
      });
    }
    res.status(500).json({ error: message || 'OCR spec plate analysis failed' });
  }
});

/**
 * 3. POST /api/vision/analyze-evdb
 * Electric Vehicle Distribution Board compliance audit.
 */
app.post('/api/vision/analyze-evdb', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }
    
    // Spec plate voltage only — phase validation (no breaker amp OCR)
    const specsContext = {
      inputVoltage: req.body.inputVoltage || null,
    };
    
    console.log('[Express DB Route] Specs context received:', specsContext);
    
    console.log('[Express DB Route] YOLO MCB/RCCB/Type-A + phase/voltage validation...');
    const yoloResult = await runYoloInference(req.file.buffer);
    const detections = yoloResult.detections || [];

    const result = analyzeEvdbCompliance({
      detections,
      specsContext,
    });

    console.log(
      `[Express DB Route] compliant=${result.isCompliant} retake=${result.retakeRequired} ` +
      `mcb=${result.mcbDetected} rccb=${result.rccbDetected} typeA=${result.typeADetected} ` +
      `expectedPhase=${result.expectedPhase} mcbPoles=${result.mcbPoles}(${result.mcbRatio?.toFixed?.(2) ?? 'n/a'}) ` +
      `rccbPoles=${result.rccbPoles}(${result.rccbRatio?.toFixed?.(2) ?? 'n/a'})`,
    );

    res.json({
      ...result,
      detections,
      yoloSuccess: yoloResult.success,
      warning: yoloResult.warning,
      specsUsed: specsContext,
      method: 'yolo_phase_voltage_validation',
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'EVDB compliance evaluation failed' });
  }
});

function isChargerClass(className) {
  const name = (className || '').toLowerCase();
  return name.includes('charger') || name.includes('gateway') || name.includes('body');
}

function normalizeDetClass(className) {
  return (className || '').toLowerCase().replace(/[\s-]+/g, '_');
}

function isIsolatorOnClass(className) {
  const name = normalizeDetClass(className);
  if (name.includes('isolator') && name.includes('on') && !name.includes('off')) return true;
  if (name.includes('switch') && name.includes('on') && !name.includes('off')) return true;
  return name.includes('isolator_on') || name === 'on' || name.endsWith('_on');
}

function isIsolatorOffClass(className) {
  const name = normalizeDetClass(className);
  if (name.includes('isolator') && name.includes('off')) return true;
  if (name.includes('switch') && name.includes('off')) return true;
  return name.includes('isolator_off') || name === 'off' || name.endsWith('_off');
}

function hasIsolatorDetection(detections) {
  if (!Array.isArray(detections)) return false;
  return detections.some((d) => {
    const name = normalizeDetClass(d.class);
    return name.includes('isolator') || isIsolatorOnClass(d.class) || isIsolatorOffClass(d.class);
  });
}

function pickIsolatorDetection(detections) {
  if (!Array.isArray(detections) || !detections.length) return null;
  const onDet = detections.filter((d) => isIsolatorOnClass(d.class));
  const offDet = detections.filter((d) => isIsolatorOffClass(d.class));
  const pool = [...onDet, ...offDet];
  if (!pool.length) return null;
  return pool.reduce((a, b) => ((b.confidence ?? 0) > (a.confidence ?? 0) ? b : a));
}

function parseIsolatorSwitchFromYolo(detections) {
  if (!Array.isArray(detections) || !detections.length) return null;

  const onDet = detections
    .filter((d) => isIsolatorOnClass(d.class))
    .reduce((best, d) => ((d.confidence ?? 0) > (best?.confidence ?? -1) ? d : best), null);
  const offDet = detections
    .filter((d) => isIsolatorOffClass(d.class))
    .reduce((best, d) => ((d.confidence ?? 0) > (best?.confidence ?? -1) ? d : best), null);

  if (onDet && offDet) {
    return (onDet.confidence ?? 0) >= (offDet.confidence ?? 0);
  }
  if (onDet) return true;
  if (offDet) return false;
  return null;
}

function parseChargerBox(raw) {
  if (!raw) return null;
  try {
    const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
    if (Array.isArray(parsed) && parsed.length === 4) {
      return parsed.map(Number);
    }
  } catch (_) {
    return null;
  }
  return null;
}

/** Pick the highest-confidence YOLO detection for the charger body. */
function pickChargerBox(detections) {
  if (!Array.isArray(detections) || !detections.length) return null;

  const chargerDets = detections.filter((d) => isChargerClass(d.class));
  if (!chargerDets.length) return null;

  const best = chargerDets.reduce((a, b) =>
    (b.confidence ?? 0) > (a.confidence ?? 0) ? b : a
  );
  return Array.isArray(best.box) && best.box.length === 4 ? best.box : null;
}

/**
 * 4. POST /api/vision/detect-gateway
 * YOLO charger body, then OpenCV red LED inside the charger region.
 */
app.post('/api/vision/detect-gateway', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }

    console.log('[Express Gateway Route] Gateway detect (warm YOLO + OpenCV)...');
    const gatewayResult = await runGatewayDetection(req.file.buffer);

    let chargerDetected = gatewayResult.chargerDetected ?? false;
    let chargerBox = gatewayResult.chargerBox ?? null;

    if (!chargerDetected && gatewayResult.mock) {
      chargerDetected = true;
      chargerBox = gatewayResult.detections?.[0]?.box ?? chargerBox;
      console.log('[Express Gateway Route] Charger assumed present (Mock mode enabled).');
    }

    if (!chargerDetected && !gatewayResult.mock) {
      console.log('[Express Gateway Route] Charger NOT detected - YOLO analysis failed or no charger in frame.');
    }

    console.log(
      `[Express Gateway Route] charger=${chargerDetected} light=${gatewayResult.lightDetected} ` +
      `color=${gatewayResult.lightColor} conf=${gatewayResult.confidence ?? 0} ` +
      `roi=${gatewayResult.opencvMethod ?? 'n/a'}`
    );

    res.json({
      success: gatewayResult.success !== false,
      chargerDetected,
      lightDetected: gatewayResult.lightDetected ?? false,
      lightColor: gatewayResult.lightColor ?? 'OFF',
      confidence: gatewayResult.confidence ?? 0,
      detections: gatewayResult.detections || [],
      chargerBox,
      yoloSuccess: gatewayResult.yoloSuccess ?? gatewayResult.success,
      opencvSuccess: true,
      opencvMethod: gatewayResult.opencvMethod,
      warning: gatewayResult.warning,
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Gateway LED classification failed' });
  }
});

/**
 * 4b. POST /api/vision/detect-red-light
 * YOLO charger region, then OpenCV red LED poll inside that region.
 */
app.post('/api/vision/detect-red-light', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }

    let chargerBox = parseChargerBox(req.body?.chargerBox);
    let routeWarning = null;

    if (!chargerBox) {
      const yoloResult = await runYoloInference(req.file.buffer);
      routeWarning = yoloResult.warning;
      chargerBox = pickChargerBox(yoloResult.detections);
      if (!chargerBox && yoloResult.mock) {
        chargerBox = yoloResult.detections?.[0]?.box ?? null;
      }
      if (!chargerBox) {
        console.log('[Express Red-Light Route] No charger ROI — skipping red LED scan.');
        return res.json({
          success: true,
          lightDetected: false,
          lightColor: 'OFF',
          confidence: 0,
          opencvMethod: 'skipped_no_charger',
          warning: routeWarning,
        });
      }
    } else {
      console.log('[Express Red-Light Route] Using cached charger ROI (skipping YOLO).');
    }

    let opencvResult = await runRedViaWorker(req.file.buffer, chargerBox);

    // Cached ROI can drift between frames — retry with a fresh YOLO box if no light found.
    if (!opencvResult.lightDetected && chargerBox) {
      const yoloResult = await runYoloInference(req.file.buffer);
      const freshBox = pickChargerBox(yoloResult.detections);
      if (freshBox) {
        const retryResult = await runRedViaWorker(req.file.buffer, freshBox);
        if (retryResult.lightDetected || (retryResult.confidence ?? 0) > (opencvResult.confidence ?? 0)) {
          opencvResult = retryResult;
          chargerBox = freshBox;
          console.log('[Express Red-Light Route] Retried with fresh YOLO charger ROI.');
        }
      }
    }

    console.log(
      `[Express Red-Light Route] light=${opencvResult.lightDetected} ` +
      `color=${opencvResult.lightColor} conf=${opencvResult.confidence ?? 0} ` +
      `ratio=${opencvResult.redPixelRatio ?? 'n/a'} method=${opencvResult.method ?? 'n/a'}`
    );

    res.json({
      success: opencvResult.success !== false,
      lightDetected: opencvResult.lightDetected ?? false,
      lightColor: opencvResult.lightColor ?? 'OFF',
      confidence: opencvResult.confidence ?? 0,
      opencvMethod: opencvResult.method,
      chargerBox,
      warning: opencvResult.warning || opencvResult.error || routeWarning,
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Red LED detection failed' });
  }
});

/**
 * 5. POST /api/vision/analyze-isolator
 * Rotary safety switch state assessment.
 */
app.post('/api/vision/analyze-isolator', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }
    
    console.log('[Express Isolator Route] YOLO isolator_on / isolator_off detection...');
    const yoloResult = await runIsolatorYoloInference(req.file.buffer);
    const detections = yoloResult.detections || [];

    console.log(
      '[Express Isolator Route] YOLO classes: ' +
      (detections.map((d) => `${d.class}(${d.confidence})`).join(', ') || 'none'),
    );

    const yoloSwitch = parseIsolatorSwitchFromYolo(detections);
    const isolatorDetected = hasIsolatorDetection(detections);

    if (yoloSwitch !== null) {
      const match = pickIsolatorDetection(detections);
      const confidence = match?.confidence ?? 0.9;
      console.log(`[Express Isolator Route] YOLO result: ${yoloSwitch ? 'ON' : 'OFF'} (${confidence})`);
      return res.json({
        success: true,
        isSwitchOn: yoloSwitch,
        isolatorDetected: true,
        confidence,
        detections,
        yoloSuccess: yoloResult.success,
        method: 'yolo',
        detectedClass: match?.class ?? null,
        warning: yoloResult.warning,
      });
    }

    console.log('[Express Isolator Route] YOLO inconclusive — no Gemini fallback (YOLO-only).');
    return res.json({
      success: false,
      isolatorDetected,
      isSwitchOn: false,
      confidence: 0,
      detections,
      yoloSuccess: yoloResult.success,
      method: 'yolo_only_failed',
      errorMessage: isolatorDetected
        ? 'YOLO found an isolator but could not determine ON/OFF. Retake a clearer photo.'
        : 'YOLO could not detect isolator_on or isolator_off. Ensure the switch is visible and retake.',
      warning: yoloResult.warning,
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Isolator toggle analysis failed' });
  }
});

/**
 * 6. POST /api/vision/analyze-pulses
 * Real video pulse count analysis using OpenCV frame extraction
 */
app.post('/api/vision/analyze-pulses', upload.single('video'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No video file uploaded' });
    }

    console.log('[Pulse Analyzer] Analyzing captured video segment...');
    const result = await analyzeBlinkingVideo(req.file.buffer);
    
    res.json({
      success: result.success,
      blinkCount: result.blinkCount || 0,
      pattern: result.pattern || null,
      correlatedErrorCode: result.correlatedErrorCode || 'analysis-failed',
      confidence: result.confidence || 0.0,
    });
  } catch (error) {
    console.error('[Pulse Analyzer] Error:', error);
    res.status(500).json({ error: error.message || 'Pulse sequence analysis failed' });
  }
});

/**
 * 7. POST /api/chat
 * Technical AI support chat copilot.
 */
app.post('/api/chat', async (req, res) => {
  try {
    const { history, message, diagnosticState } = req.body;
    if (!message) {
      return res.status(400).json({ error: 'Message content is required' });
    }
    console.log(`[Express Chat Route] Exchanging technical chat context for prompt: "${message.substring(0, 40)}..."`);
    const result = await chatAssistant(history, message, diagnosticState);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message || 'Chat assistant consultation failed' });
  }
});

// Root endpoint for status checks
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Boot the server
warmVisionWorker();
app.listen(PORT, '0.0.0.0', () => {
  console.log(`================================================================`);
  console.log(` REXHARGE EV DIAGNOSTICS PROXY SERVER RUNNING`);
  console.log(` Endpoint: http://localhost:${PORT}`);
  console.log(` Mode: ${process.env.GEMINI_API_KEY ? 'Active Gemini AI' : 'Simulated Offline Mock'}`);
  console.log(` Vision: warm YOLO worker (model preloaded at startup)`);
  console.log(`================================================================`);
});
