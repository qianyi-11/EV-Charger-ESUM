import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { resolvePythonExecutable } from './python_util.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const MODEL_PATH = path.join(__dirname, '..', 'models', 'my_model.pt');
const WORKER_SCRIPT = path.join(__dirname, 'vision_worker.py');

let workerProcess = null;
let workerReady = false;
let workerMock = false;
let pendingRequests = [];
let requestId = 0;
const responseWaiters = new Map();

function ensureTempDir() {
  const tempDir = path.join(__dirname, '..', 'temp');
  if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
  }
  return tempDir;
}

function writeTempImage(imageBuffer) {
  ensureTempDir();
  const tempFilePath = path.join(
    ensureTempDir(),
    `vision_${Date.now()}_${Math.round(Math.random() * 1e9)}.jpg`,
  );
  fs.writeFileSync(tempFilePath, imageBuffer);
  return tempFilePath;
}

function cleanupTempImage(tempFilePath) {
  fs.unlink(tempFilePath, () => {});
}

function startWorker() {
  if (workerProcess) return;

  const python = resolvePythonExecutable();
  workerProcess = spawn(python, [WORKER_SCRIPT, MODEL_PATH], {
    stdio: ['pipe', 'pipe', 'pipe'],
  });

  let stdoutBuffer = '';

  workerProcess.stdout.on('data', (chunk) => {
    stdoutBuffer += chunk.toString();
    const lines = stdoutBuffer.split('\n');
    stdoutBuffer = lines.pop() ?? '';

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) continue;

      let parsed;
      try {
        parsed = JSON.parse(trimmed);
      } catch {
        console.warn('[Vision Worker] Non-JSON stdout:', trimmed.slice(0, 120));
        continue;
      }

      if (parsed.ready !== undefined) {
        workerReady = parsed.ready;
        workerMock = Boolean(parsed.mock);
        console.log(
          `[Vision Worker] Ready (modelLoaded=${parsed.modelLoaded ?? false}, mock=${workerMock})`,
        );
        continue;
      }

      const id = pendingRequests.shift();
      const waiter = id !== undefined ? responseWaiters.get(id) : null;
      if (waiter) {
        responseWaiters.delete(id);
        waiter.resolve(parsed);
      }
    }
  });

  workerProcess.stderr.on('data', (data) => {
    const msg = data.toString().trim();
    if (msg) console.warn('[Vision Worker] stderr:', msg);
  });

  workerProcess.on('close', (code) => {
    console.warn(`[Vision Worker] Exited with code ${code}`);
    workerProcess = null;
    workerReady = false;

    for (const [, waiter] of responseWaiters) {
      waiter.reject(new Error('Vision worker process exited'));
    }
    responseWaiters.clear();
    pendingRequests = [];
  });
}

function sendWorkerCommand(payload, timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    startWorker();

    const id = requestId++;
    pendingRequests.push(id);
    responseWaiters.set(id, { resolve, reject });

    const timer = setTimeout(() => {
      if (responseWaiters.has(id)) {
        responseWaiters.delete(id);
        const idx = pendingRequests.indexOf(id);
        if (idx >= 0) pendingRequests.splice(idx, 1);
        reject(new Error('Vision worker request timed out'));
      }
    }, timeoutMs);

    const finish = (fn, value) => {
      clearTimeout(timer);
      fn(value);
    };

    const originalResolve = responseWaiters.get(id).resolve;
    const originalReject = responseWaiters.get(id).reject;
    responseWaiters.set(id, {
      resolve: (v) => finish(originalResolve, v),
      reject: (e) => finish(originalReject, e),
    });

    const write = () => {
      if (!workerProcess?.stdin?.writable) {
        finish(reject, new Error('Vision worker stdin not writable'));
        return;
      }
      workerProcess.stdin.write(`${JSON.stringify(payload)}\n`);
    };

    if (workerReady) {
      write();
    } else {
      const waitReady = setInterval(() => {
        if (workerReady) {
          clearInterval(waitReady);
          write();
        } else if (!workerProcess) {
          clearInterval(waitReady);
          finish(reject, new Error('Vision worker failed to start'));
        }
      }, 50);
    }
  });
}

async function withTempImage(imageBuffer, fn) {
  const tempFilePath = writeTempImage(imageBuffer);
  try {
    return await fn(tempFilePath);
  } finally {
    cleanupTempImage(tempFilePath);
  }
}

/** Combined YOLO + OpenCV gateway detection in one warm-worker call. */
export async function runGatewayDetection(imageBuffer) {
  try {
    return await withTempImage(imageBuffer, async (tempFilePath) => {
      const result = await sendWorkerCommand({ cmd: 'gateway', image: tempFilePath });
      if (result.mock) {
        return {
          ...result,
          mock: true,
          warning: result.warning || 'Running in simulated mode. Install ultralytics for real weights.',
        };
      }
      return result;
    });
  } catch (err) {
    console.error('[Vision Worker] Gateway detection failed:', err.message);
    return {
      success: false,
      chargerDetected: false,
      lightDetected: false,
      lightColor: 'OFF',
      confidence: 0,
      detections: [],
      error: err.message,
    };
  }
}

/** YOLO-only inference via warm worker (model stays loaded). */
export async function runYoloViaWorker(imageBuffer, options = {}) {
  return withTempImage(imageBuffer, async (tempFilePath) => {
    const result = await sendWorkerCommand({
      cmd: options.isolator ? 'isolator' : 'yolo',
      image: tempFilePath,
      imgsz: options.imgsz,
      conf: options.conf,
    });
    if (result.mock) {
      return {
        success: true,
        mock: true,
        warning: 'Running in simulated mode. Install ultralytics for real weights.',
        detections: [{ class: 'ev_charger', confidence: 0.98, box: [50, 100, 400, 800] }],
      };
    }
    return result;
  });
}

/** OpenCV red LED via warm worker (fast — no YOLO reload). */
export async function runRedViaWorker(imageBuffer, chargerBox) {
  return withTempImage(imageBuffer, async (tempFilePath) => {
    return sendWorkerCommand({
      cmd: 'red',
      image: tempFilePath,
      box: chargerBox,
    });
  });
}

/** Start worker at server boot so first scan is not slow. */
export function warmVisionWorker() {
  startWorker();
}
