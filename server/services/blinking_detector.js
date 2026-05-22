import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';

/**
 * Analyzes a video file to detect blinking pattern and count blinks
 * Uses OpenCV via Python for video frame extraction and analysis
 */
export async function analyzeBlinkingVideo(videoBuffer, videoPath) {
  try {
    console.log('[Blinking Detector] Starting video analysis...');
    
    // Write buffer to temp file if needed
    let inputVideoPath = videoPath;
    if (!inputVideoPath && videoBuffer) {
      inputVideoPath = path.join(process.cwd(), 'temp', `video_${Date.now()}.mp4`);
      fs.writeFileSync(inputVideoPath, videoBuffer);
    }

    // Extract frames and analyze for red light blinking
    const result = await extractFramesAndDetectBlinks(inputVideoPath);
    
    // Clean up temp file
    if (!videoPath && inputVideoPath) {
      try {
        fs.unlinkSync(inputVideoPath);
      } catch (e) {
        // Ignore cleanup errors
      }
    }

    return result;
  } catch (error) {
    console.error('[Blinking Detector] Error:', error);
    throw error;
  }
}

/**
 * Extracts frames from video and detects red light blinking
 */
async function extractFramesAndDetectBlinks(videoPath) {
  return new Promise((resolve, reject) => {
    // Use Python script for frame extraction and red light detection
    const pythonScript = path.join(process.cwd(), 'services', 'blinking_analyzer.py');
    
    const pythonProcess = spawn('python', [pythonScript, videoPath], {
      cwd: process.cwd(),
    });

    let stdout = '';
    let stderr = '';

    pythonProcess.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      stderr += data.toString();
      console.error('[Blinking Detector] Python stderr:', data.toString());
    });

    pythonProcess.on('close', (code) => {
      try {
        if (code !== 0) {
          console.warn(`[Blinking Detector] Python process exited with code ${code}`);
          // Fallback to simple analysis
          resolve({
            success: false,
            blinkCount: 0,
            correlatedErrorCode: 'analysis-failed',
            confidence: 0.0,
            message: stderr || 'Python analysis failed',
          });
          return;
        }

        const result = JSON.parse(stdout.trim());
        console.log('[Blinking Detector] Analysis result:', result);
        
        resolve({
          success: result.success || false,
          blinkCount: result.blink_count || 0,
          correlatedErrorCode: generateErrorCode(result.blink_count || 0),
          confidence: result.confidence || 0.0,
        });
      } catch (error) {
        console.error('[Blinking Detector] Parse error:', error);
        reject(error);
      }
    });

    pythonProcess.on('error', (error) => {
      console.error('[Blinking Detector] Process error:', error);
      reject(error);
    });
  });
}

/**
 * Generate error code based on blink count
 */
function generateErrorCode(blinkCount) {
  if (blinkCount === 0) {
    return 'solid-red';  // No blinking = solid red light
  } else if (blinkCount >= 1 && blinkCount <= 3) {
    return `blink-${blinkCount}`;
  } else if (blinkCount >= 4 && blinkCount <= 6) {
    return `blink-${blinkCount}-rapid`;
  } else {
    return `blink-${blinkCount}-very-rapid`;
  }
}
