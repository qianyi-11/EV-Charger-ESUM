import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parsePythonJson, runPythonScript } from './python_util.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const MODEL_PATH = path.join(__dirname, '..', 'models', 'my_model.pt');
const SCRIPT_PATH = path.join(__dirname, 'yolo_inference.py');

/**
 * Runs YOLOv8/11 object detection using the custom weights file.
 * Saves the buffer as a temporary file, invokes python child process, and parses JSON output.
 */
export function runYoloInference(imageBuffer) {
  return new Promise((resolve) => {
    // 1. Create a unique temporary filename
    const tempDir = path.join(__dirname, '..', 'temp');
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }
    
    const tempFilename = `yolo_in_${Date.now()}_${Math.round(Math.random() * 1e9)}.jpg`;
    const tempFilePath = path.join(tempDir, tempFilename);

    // 2. Write buffer to disk
    fs.writeFile(tempFilePath, imageBuffer, (err) => {
      if (err) {
        console.error('[YOLO Service] Temp file write failed:', err);
        return resolve({
          success: false,
          error: 'Failed to write temporary image file for model inference.',
          detections: []
        });
      }

      console.log(`[YOLO Service] Running YOLO inference on: ${tempFilePath}`);
      runPythonScript(SCRIPT_PATH, [tempFilePath, MODEL_PATH]).then(({ code, stdoutData, stderrData, python }) => {
        fs.unlink(tempFilePath, (unlinkErr) => {
          if (unlinkErr) console.error('[YOLO Service] Failed to delete temp file:', unlinkErr);
        });

        if (stderrData.includes('No module named') || stdoutData.includes('ultralytics is not installed')) {
          console.log('[YOLO Service] Ultralytics missing — using charger_body mock.');
          return resolve({
            success: true,
            mock: true,
            warning: 'Running in simulated mode. Install ultralytics for real weights.',
            detections: [{ class: 'charger_body', confidence: 0.98, box: [50, 100, 400, 800] }],
          });
        }

        try {
          const result = parsePythonJson(stdoutData);
          if (result.success === false && result.error?.includes('not found')) {
            console.warn('[YOLO Service] Model missing:', result.error);
          }
          return resolve(result);
        } catch (parseErr) {
          console.error(`[YOLO Service] JSON parse failed (${python}):`, parseErr.message);
          if (code !== 0) {
            console.warn('[YOLO Service] stderr:', stderrData);
          }
          return resolve({
            success: false,
            error: parseErr.message || 'Malformed JSON from YOLO script.',
            detections: [],
          });
        }
      });
    });
  });
}
