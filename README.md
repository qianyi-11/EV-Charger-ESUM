# Rexharge — EVision AI EV Charger Diagnostic System

**Rexharge** is an AI-powered mobile diagnostic platform for Electric Vehicle (EV) charging infrastructure. Built for field technicians and maintenance engineers, it combines on-device computer vision, cloud AI inference, and YOLO-based object detection to inspect, diagnose, and report on EV charger health — all through a smartphone camera.

---

## 🚀 Key Features

- **OCR Spec Plate Scanner**: Capture the charger's specification plate and automatically extract brand, model, serial number, input voltage, and output current using Google ML Kit + Gemini AI.
- **Charger Body & LED Detection**: Detect the charger unit and classify its indicator LED colour (red/green/amber) using a hybrid YOLO + OpenCV pipeline — no manual inspection needed.
- **EVDB Compliance Audit**: Photograph the Electric Vehicle Distribution Board and receive a Gemini-powered compliance assessment cross-referenced with charger specs (voltage, current ratings).
- **Isolator Switch Analysis**: Detect whether the rotary safety isolator is in the ON or OFF position using hybrid YOLO + Gemini reasoning.
- **LED Blink Pulse Diagnosis**: Record a short video of a blinking indicator, and the system counts blink pulses via OpenCV frame analysis to correlate them with manufacturer error codes.
- **AI Assistant Chat**: Context-aware Gemini-powered chat assistant with full diagnostic state awareness — ask technical questions, get guided troubleshooting steps.
- **PDF Report Generation**: Auto-generate structured diagnostic reports from each inspection session, ready for export and archiving.
- **Offline-Resilient Mode**: Graceful degradation when the backend server is unreachable — on-device ML Kit handles core OCR tasks locally.
- **Firebase Cloud Sync**: Diagnostic history and activity logs are persisted to Cloud Firestore for cross-device access.

---

## 🧱 Architecture Overview

```
┌─────────────────────────────────┐
│     Flutter Mobile App (Dart)   │
│  ┌─────────┐  ┌──────────────┐  │
│  │ ML Kit  │  │  Gemini SDK  │  │  ← On-device OCR + Direct AI
│  └─────────┘  └──────────────┘  │
│         ↕  HTTP (multipart)     │
├─────────────────────────────────┤
│   Node.js / Express Server      │
│  ┌──────────┐  ┌─────────────┐  │
│  │ Gemini   │  │ YOLO + CV2  │  │  ← AI vision proxy + Python workers
│  │  (GenAI) │  │  (Python)   │  │
│  └──────────┘  └─────────────┘  │
└─────────────────────────────────┘
              ↕
      Firebase Firestore
```

### Flutter App (`/lib`)

| Layer | Description |
|---|---|
| `screens/` | All UI screens — OCR, charger detection, EVDB, isolator, blink recorder, report, chat |
| `services/` | Business logic — server connectivity, OCR handler, report generator, offline manager, routing engine |
| `models/` | `DiagnosticState` — shared state model passed through the full inspection workflow |
| `widgets/` | Reusable UI components (glassmorphism containers, animated orbs, etc.) |
| `theme/` | App-wide dark theme tokens and colour system |

### Backend Server (`/server`)

| File / Folder | Description |
|---|---|
| `server.js` | Express REST API — 7 vision endpoints + chat endpoint |
| `services/gemini.js` | Gemini API wrapper — blur check, OCR, EVDB audit, isolator analysis, chat assistant |
| `services/yolo.js` | Calls Python YOLO inference worker via child process |
| `services/opencv.js` | Calls Python OpenCV red LED detector |
| `services/blinking_detector.js` | Calls Python video blink counter |
| `services/yolo_inference.py` | YOLO object detection inference script |
| `services/opencv_red_detect.py` | HSV-based red LED colour detection |
| `services/blinking_analyzer.py` | Frame-by-frame blink pulse counting from video |

---

## 🔌 API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/vision/check-blur` | Image sharpness / blur pre-check |
| `POST` | `/api/vision/ocr` | Spec plate OCR extraction |
| `POST` | `/api/vision/analyze-evdb` | EVDB compliance audit (YOLO + Gemini) |
| `POST` | `/api/vision/detect-gateway` | Charger body + LED colour detection |
| `POST` | `/api/vision/detect-red-light` | Fast OpenCV-only red LED poll |
| `POST` | `/api/vision/analyze-isolator` | Isolator switch ON/OFF detection |
| `POST` | `/api/vision/analyze-pulses` | LED blink video pulse count |
| `POST` | `/api/chat` | AI assistant technical chat |
| `GET` | `/health` | Server health check |

---

## ⚙️ Prerequisites

- **Flutter** SDK ≥ 3.11.5 / Dart SDK ^3.11.5
- **Node.js** 18+ and npm
- **Python** 3.9+ (for YOLO / OpenCV workers)
- A **Google Gemini API Key** — obtain from [Google AI Studio](https://aistudio.google.com/)
- A **Firebase project** with Firestore enabled

---

## 🖥 Backend Setup (Express + AI Server)

```bash
cd server
npm install
```

Configure environment variables by copying the example file:

```bash
# Windows
copy .env.example .env

# macOS / Linux
cp .env.example .env
```

Edit `.env` and fill in your Gemini API key:

```env
PORT=5000
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
```

Install Python dependencies (for YOLO + OpenCV workers):

```bash
pip install ultralytics opencv-python-headless numpy
```

Start the backend server:

```bash
# Production
npm start

# Development (auto-reload)
npm run dev
```

The API will be available at: `http://localhost:5000`

---

## 📱 Flutter App Setup

```bash
flutter pub get
```

Configure Firebase by updating `lib/firebase_options.dart` with your project's credentials (or run `flutterfire configure`).

Point the app to your backend server from **Settings** inside the app, or update the default server URL in `lib/services/server_connectivity_service.dart`.

Run the app:

```bash
# Android / iOS
flutter run

# Web
flutter run -d chrome
```

---

## 🔬 Diagnostic Workflow

```
1. Scan Spec Plate (OCR)
       ↓  Extract brand / model / voltage / current
2. Detect Charger Body & LED
       ↓  Confirm charger present + read indicator colour
3. Inspect EVDB (Distribution Board)
       ↓  Compliance check against extracted specs
4. Check Isolator Switch
       ↓  Confirm safety switch state (ON / OFF)
5. Record Blink Pattern (if error LED active)
       ↓  Count pulses → correlate to error code
6. Review Diagnosis Result
       ↓  Recommended action + AI assistant follow-up
7. Export PDF Report
```

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| On-device OCR | Google ML Kit Text Recognition |
| On-device AI | Google Generative AI SDK (`google_generative_ai`) |
| Backend API | Node.js + Express |
| Cloud AI | Google Gemini (`@google/genai`) |
| Object Detection | YOLOv8 (via `ultralytics` Python) |
| Computer Vision | OpenCV (`cv2`) |
| Database | Firebase Cloud Firestore |
| Report Generation | `pdf` + `printing` Flutter packages |
| Local Storage | `sqflite` + `shared_preferences` |

---

## 📂 Project Structure

```
rexharge/
├── lib/                        # Flutter app source
│   ├── main.dart               # App entry point + routing
│   ├── firebase_options.dart   # Firebase configuration
│   ├── models/
│   │   └── diagnostic_state.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── ocr_detection_screen.dart
│   │   ├── charger_detection_screen.dart
│   │   ├── diagnosis_result_screen.dart
│   │   ├── report_preview_screen.dart
│   │   ├── assistant_chat_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── branch_power/       # EVDB + Isolator screens
│   │   └── branch_blink/       # Video blink recorder screen
│   ├── services/
│   │   ├── server_connectivity_service.dart
│   │   ├── ml_model_service.dart
│   │   ├── ocr_handler.dart
│   │   ├── report_generator.dart
│   │   ├── offline_manager.dart
│   │   └── routing_engine.dart
│   ├── widgets/                # Reusable UI components
│   └── theme/                  # Dark theme + colour tokens
│
├── server/                     # Node.js backend
│   ├── server.js               # Express API server
│   ├── services/
│   │   ├── gemini.js           # Gemini AI integration
│   │   ├── yolo.js             # YOLO object detection
│   │   ├── yolo_inference.py
│   │   ├── opencv.js           # OpenCV LED detection
│   │   ├── opencv_red_detect.py
│   │   ├── blinking_detector.js
│   │   └── blinking_analyzer.py
│   ├── .env.example
│   └── package.json
│
├── pubspec.yaml                # Flutter dependencies
├── firebase.json               # Firebase hosting config
└── firestore.rules             # Firestore security rules
```

---

## 🔐 Environment & Security

- The Gemini API key is **never embedded in the Flutter app** — all sensitive AI calls are proxied through the backend server.
- Firestore security rules are defined in `firestore.rules`.
- The server falls back to a simulated offline mock mode when no `GEMINI_API_KEY` is set (development convenience only).

---

## 📄 License

This project is private and not published to pub.dev. All rights reserved.
