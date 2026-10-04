# EVision 

EVision is a Flutter-based EV charger inspection and diagnostic application designed to help technicians quickly assess charger health, capture specification details, and review fault conditions through guided workflows.

This project presents a modern mobile-first diagnostic dashboard for EV charging equipment, combining image capture, visual scanning, result tracking, and an AI-style troubleshooting assistant.

## Overview

The application supports a structured inspection workflow:

- Capture charger specification plate details using OCR-style flow
- Detect charger status indicators such as red light conditions
- Guide the user through branch-specific checks
- Capture photo or video evidence for diagnosis
- Review results and generate a report summary
- Use an AI assistant for troubleshooting questions and guidance

## Key Features

- Smart charger dashboard with quick actions
- Unified detection workflow for charger inspection
- Photo-based isolator and EVDB checks
- Video recording mode for real-time charger diagnostics
- Diagnostic result pages and report previews
- AI-powered assistant for troubleshooting suggestions
- Cross-platform Flutter UI for Android, iOS, Web, Windows, Linux, and macOS
- Dark theme and professional monitoring dashboard styling

## Application Flow

1. Launch the app and access the home dashboard.
2. Start a charger diagnosis flow from the main screen.
3. Capture the charger spec plate and extract model/serial information.
4. Run the light scanning check to determine the charger condition.
5. Continue with the appropriate branch:
   - Photo-based inspection path
   - Video analysis path
6. Review diagnostic results and generate a report.
7. Ask the AI assistant for troubleshooting guidance.

## Project Structure

```text
.
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── web/
├── lib/
│   ├── components/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   ├── widgets/
│   ├── main.dart
│   └── responsive_layout.dart
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
├── .gitignore
└── .metadata
```

## Main Screens

- `SplashScreen` – initial startup screen
- `HomeScreen` – dashboard and quick actions
- `UnifiedDetectionScreen` – charger inspection workflow
- `PhotoIsolatorScreen` – isolator-related image check
- `PhotoEVDBScreen` – EVDB inspection workflow
- `VideoRecordingScreen` – charger recording mode
- `DiagnosisResultNewScreen` – result display
- `AIAssistantScreen` – troubleshooting assistant UI
- `ReportPreviewScreen` – report summary view
- `SettingsScreen` – app settings

## Tech Stack

- Flutter
- Dart
- Material Design UI
- `animate_do` for animations
- `fl_chart` for charting
- `shimmer` for loading states
- `percent_indicator` for status indicators
- `toastification` for notifications

## Getting Started

### Prerequisites

- Flutter SDK (3.11 or newer recommended)
- Android Studio / Xcode / VS Code
- An emulator or physical device

### Installation

```bash
git clone https://github.com/qianyi-11/EV-Charger-ESUM.git
cd EV-Charger-ESUM
flutter pub get
flutter run
```

### Run on a specific platform

```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

## Notes

This repository is structured as a diagnostic prototype and UI-driven EV charger inspection app. Some flows are simulated for demonstration purposes and can be extended with real OCR, camera integration, backend APIs, or charger-manufacturer-specific validation logic.

## License

This project is currently unlicensed unless otherwise specified in the repository.

## Contributing

Contributions are welcome. If you are improving the diagnostic flow, UI, or backend integration, please open an issue or submit a pull request with a clear summary of the change.

## Contact

Repository: https://github.com/qianyi-11/EV-Charger-ESUM
