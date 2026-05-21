import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

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

      // 3. Spawn PyLauncher 'py' child process
      console.log(`[YOLO Service] Running YOLO inference on: ${tempFilePath}`);
      const pythonProcess = spawn('py', [SCRIPT_PATH, tempFilePath, MODEL_PATH]);

      let stdoutData = '';
      let stderrData = '';

      pythonProcess.stdout.on('data', (data) => {
        stdoutData += data.toString();
      });

      pythonProcess.stderr.on('data', (data) => {
        stderrData += data.toString();
      });

      pythonProcess.on('close', (code) => {
        // Always clean up the temp file
        fs.unlink(tempFilePath, (unlinkErr) => {
          if (unlinkErr) console.error('[YOLO Service] Failed to delete temp file:', unlinkErr);
        });

        if (code !== 0) {
          console.warn(`[YOLO Service] Python process exited with code ${code}. Stderr:`, stderrData);
          
          // Let's check if the error is due to ultralytics not installed and fall back
          if (stderrData.includes('No module named') || stdoutData.includes('ultralytics is not installed')) {
            console.log('[YOLO Service] Falling back to high-fidelity mock detections due to missing ultralytics package.');
            return resolve({
              success: true,
              mock: true,
              warning: 'Running in simulated mode. Install ultralytics to execute your physical .pt weights: py -m pip install ultralytics',
              detections: [
                { class: 'mcb', confidence: 0.96, box: [120, 200, 320, 450] },
                { class: 'rccb', confidence: 0.94, box: [340, 200, 540, 450] },
                { class: 'isolator', confidence: 0.97, box: [560, 250, 700, 400] },
                { class: 'charger_body', confidence: 0.98, box: [50, 100, 400, 800] }
              ]
            });
          }

          return resolve({
            success: false,
            error: `Python inference process failed with code ${code}: ${stderrData}`,
            detections: []
          });
        }

        try {
          // Parse stdout output as JSON
          const result = JSON.parse(stdoutData.trim());
          resolve(result);
        } catch (parseErr) {
          console.error('[YOLO Service] Failed to parse python output:', parseErr, 'Raw output:', stdoutData);
          resolve({
            success: false,
            error: 'Inference script returned malformed JSON output.',
            detections: []
          });
        }
      });
    });
  });
}
