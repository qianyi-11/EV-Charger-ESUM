import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parsePythonJson, runPythonScript } from './python_util.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const SCRIPT_PATH = path.join(__dirname, 'opencv_red_detect.py');

/**
 * OpenCV HSV red LED detection scoped to the YOLO charger bounding box.
 * @param {Buffer} imageBuffer
 * @param {number[]|null} chargerBox - [x1, y1, x2, y2] from YOLO, or null for fallback crop
 */
export function runOpenCvRedDetection(imageBuffer, chargerBox = null) {
  return new Promise((resolve) => {
    const tempDir = path.join(__dirname, '..', 'temp');
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    const tempFilename = `opencv_red_${Date.now()}_${Math.round(Math.random() * 1e9)}.jpg`;
    const tempFilePath = path.join(tempDir, tempFilename);

    fs.writeFile(tempFilePath, imageBuffer, (err) => {
      if (err) {
        console.error('[OpenCV Service] Temp file write failed:', err);
        return resolve({
          success: false,
          lightDetected: false,
          lightColor: 'OFF',
          confidence: 0,
          error: 'Failed to write temporary image file.',
        });
      }

      const scriptArgs = [tempFilePath];
      if (Array.isArray(chargerBox) && chargerBox.length === 4) {
        scriptArgs.push(...chargerBox.map((v) => String(v)));
        console.log(`[OpenCV Service] Running red LED detection in charger ROI: ${chargerBox.join(', ')}`);
      } else {
        console.log(`[OpenCV Service] Running red LED detection (no charger ROI — fallback crop)`);
      }

      runPythonScript(SCRIPT_PATH, scriptArgs).then(({ code, stdoutData, stderrData, python }) => {
        fs.unlink(tempFilePath, (unlinkErr) => {
          if (unlinkErr) console.error('[OpenCV Service] Failed to delete temp file:', unlinkErr);
        });

        try {
          const result = parsePythonJson(stdoutData);
          console.log(
            `[OpenCV Service] red=${result.lightDetected} color=${result.lightColor} ` +
            `ratio=${result.redPixelRatio ?? 'n/a'} method=${result.method ?? 'n/a'}`
          );
          resolve({
            success: result.success !== false,
            lightDetected: Boolean(result.lightDetected),
            lightColor: result.lightColor || 'OFF',
            confidence: result.confidence ?? 0,
            redPixelRatio: result.redPixelRatio,
            maxBlobArea: result.maxBlobArea,
            method: result.method,
            warning: result.error,
          });
        } catch (parseErr) {
          console.error(`[OpenCV Service] JSON parse failed (${python}, code=${code}):`, parseErr.message);
          if (stderrData) console.warn('[OpenCV Service] stderr:', stderrData);
          resolve({
            success: false,
            lightDetected: false,
            lightColor: 'OFF',
            confidence: 0,
            error: parseErr.message || 'Malformed JSON from OpenCV script.',
          });
        }
      });
    });
  });
}
