import express from 'express';
import cors from 'cors';
import multer from 'multer';
import dotenv from 'dotenv';
import {
  checkBlur,
  processOcr,
  analyzeEvdb,
  analyzeIsolator,
  chatAssistant
} from './services/gemini.js';
import { runYoloInference } from './services/yolo.js';
import { runOpenCvRedDetection } from './services/opencv.js';
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
 * 1. POST /api/vision/check-blur
 * Ahead-of-time blur/shake checking.
 */
app.post('/api/vision/check-blur', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }
    const result = await checkBlur(req.file.buffer);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message || 'Image clarity check failed' });
  }
});

/**
 * 2. POST /api/vision/ocr
 * Spec Plate recognition and text parameter extraction.
 */
app.post('/api/vision/ocr', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }
    const result = await processOcr(req.file.buffer);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message || 'OCR spec plate analysis failed' });
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
    
    // Perform hybrid detection: local YOLO + Gemini cognitive inspection
    console.log('[Express DB Route] Initiating hybrid YOLO & Gemini analysis...');
    const yoloResult = await runYoloInference(req.file.buffer);
    const geminiResult = await analyzeEvdb(req.file.buffer);
    
    res.json({
      ...geminiResult,
      detections: yoloResult.detections || [],
      yoloSuccess: yoloResult.success,
      warning: yoloResult.warning
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'EVDB compliance evaluation failed' });
  }
});

/**
 * 4. POST /api/vision/detect-gateway
 * YOLO charger body + OpenCV red LED detection.
 */
app.post('/api/vision/detect-gateway', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }

    console.log('[Express Gateway Route] YOLO charger + OpenCV red LED...');
    const [yoloResult, opencvResult] = await Promise.all([
      runYoloInference(req.file.buffer),
      runOpenCvRedDetection(req.file.buffer),
    ]);

    let chargerDetected = false;
    if (yoloResult.success && yoloResult.detections?.length) {
      chargerDetected = yoloResult.detections.some((d) => {
        const name = (d.class || '').toLowerCase();
        return name.includes('charger') || name.includes('gateway') || name.includes('body');
      });
    }

    // Only assume charger is present in mock/simulation mode (never in production failure)
    if (!chargerDetected && yoloResult.mock) {
      chargerDetected = true;
      console.log('[Express Gateway Route] Charger assumed present (Mock mode enabled).');
    }
    
    if (!chargerDetected && !yoloResult.mock) {
      console.log('[Express Gateway Route] Charger NOT detected - YOLO analysis failed or no charger in frame.');
    }

    console.log(
      `[Express Gateway Route] charger=${chargerDetected} light=${opencvResult.lightDetected} ` +
      `color=${opencvResult.lightColor}`
    );

    res.json({
      success: true,
      chargerDetected,
      lightDetected: opencvResult.lightDetected,
      lightColor: opencvResult.lightColor,
      confidence: opencvResult.confidence ?? 0,
      detections: yoloResult.detections || [],
      yoloSuccess: yoloResult.success,
      opencvSuccess: opencvResult.success,
      opencvMethod: opencvResult.method,
      warning: opencvResult.warning || yoloResult.warning,
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Gateway LED classification failed' });
  }
});

/**
 * 4b. POST /api/vision/detect-red-light
 * Fast OpenCV-only poll while the app scans for a red LED.
 */
app.post('/api/vision/detect-red-light', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }
    const opencvResult = await runOpenCvRedDetection(req.file.buffer);
    res.json({
      success: opencvResult.success,
      lightDetected: opencvResult.lightDetected,
      lightColor: opencvResult.lightColor,
      confidence: opencvResult.confidence ?? 0,
      opencvMethod: opencvResult.method,
      warning: opencvResult.warning,
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
    
    // Perform hybrid detection: local YOLO + Gemini toggle inspection
    console.log('[Express Isolator Route] Initiating hybrid YOLO & Gemini analysis...');
    const yoloResult = await runYoloInference(req.file.buffer);
    const geminiResult = await analyzeIsolator(req.file.buffer);
    
    let isSwitchOn = geminiResult.isSwitchOn;
    // Let YOLO override if it detects 'on' or 'off'
    if (yoloResult.success && yoloResult.detections) {
      const onDet = yoloResult.detections.find(d => d.class.toLowerCase().includes('on'));
      const offDet = yoloResult.detections.find(d => d.class.toLowerCase().includes('off'));
      if (onDet) isSwitchOn = true;
      else if (offDet) isSwitchOn = false;
    }
    
    res.json({
      ...geminiResult,
      isSwitchOn,
      detections: yoloResult.detections || [],
      yoloSuccess: yoloResult.success,
      warning: yoloResult.warning
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
app.listen(PORT, '0.0.0.0', () => {
  console.log(`================================================================`);
  console.log(` REXHARGE EV DIAGNOSTICS PROXY SERVER RUNNING`);
  console.log(` Endpoint: http://localhost:${PORT}`);
  console.log(` Mode: ${process.env.GEMINI_API_KEY ? 'Active Gemini AI' : 'Simulated Offline Mock'}`);
  console.log(`================================================================`);
});
