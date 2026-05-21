import fs from 'fs';
import { spawn } from 'child_process';

const WINDOWS_PYTHON_CANDIDATES = [
  process.env.PYTHON,
  process.env.PYTHON_PATH,
  'C:\\Users\\meiru\\AppData\\Local\\Python\\pythoncore-3.14-64\\python.exe',
  'C:\\Users\\meiru\\AppData\\Local\\Programs\\Python\\Python314\\python.exe',
  'C:\\Users\\meiru\\AppData\\Local\\Microsoft\\WindowsApps\\python.exe',
  'python',
  'python3',
  'py',
].filter(Boolean);

let cachedPython = null;

export function resolvePythonExecutable() {
  if (cachedPython) return cachedPython;
  for (const candidate of WINDOWS_PYTHON_CANDIDATES) {
    if (candidate.endsWith('.exe') && fs.existsSync(candidate)) {
      cachedPython = candidate;
      return cachedPython;
    }
  }
  cachedPython = process.env.PYTHON || 'python';
  return cachedPython;
}

/** Ultralytics/OpenCV sometimes print banners before JSON — take the last JSON line. */
export function parsePythonJson(stdout) {
  const trimmed = stdout.trim();
  if (!trimmed) throw new Error('Empty python stdout');

  try {
    return JSON.parse(trimmed);
  } catch (_) {
    const lines = trimmed.split('\n').map((l) => l.trim()).filter(Boolean);
    for (let i = lines.length - 1; i >= 0; i--) {
      const line = lines[i];
      if (line.startsWith('{') || line.startsWith('[')) {
        return JSON.parse(line);
      }
    }
    throw new Error(`No JSON object in python output: ${trimmed.slice(0, 200)}`);
  }
}

export function runPythonScript(scriptPath, args = []) {
  return new Promise((resolve) => {
    const python = resolvePythonExecutable();
    const pythonProcess = spawn(python, [scriptPath, ...args]);

    let stdoutData = '';
    let stderrData = '';

    pythonProcess.stdout.on('data', (data) => {
      stdoutData += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      stderrData += data.toString();
    });

    pythonProcess.on('close', (code) => {
      resolve({ code, stdoutData, stderrData, python });
    });
  });
}
