import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ocr_detection_screen.dart';
import 'screens/charger_detection_screen.dart';
import 'screens/branch_power/isolator_detection_screen.dart';
import 'screens/branch_power/evdb_detection_screen.dart';
import 'screens/branch_blink/video_recording_screen.dart';
import 'screens/report_preview_screen.dart';
import 'screens/assistant_chat_screen.dart';
import 'screens/diagnosis_result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RexhargeApp());
}

class RexhargeApp extends StatelessWidget {
  const RexhargeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rexharge EV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/unified-detection': (context) => const OcrDetectionScreen(),
        '/charger-detection': (context) => const ChargerDetectionScreen(),
        '/isolator-detection': (context) => const IsolatorDetectionScreen(),
        '/evdb-detection': (context) => const EvdbDetectionScreen(),
        '/video-recording': (context) => const VideoRecordingScreen(),
        '/report': (context) => const ReportPreviewScreen(),
        '/assistant': (context) => const AssistantChatScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/diagnosis/')) {
          final errorCode = settings.name!.replaceFirst('/diagnosis/', '');
          return MaterialPageRoute(
            builder: (context) => DiagnosisResultScreen(errorCode: errorCode),
          );
        }
        return null;
      },
    );
  }
}
