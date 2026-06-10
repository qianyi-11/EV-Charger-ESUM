import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/auth/auth_gate.dart';
import 'screens/main_shell.dart';
import 'screens/settings_screen.dart';
import 'screens/ocr_detection_screen.dart';
import 'screens/charger_detection_screen.dart';
import 'screens/branch_power/isolator_detection_screen.dart';
import 'screens/branch_power/evdb_detection_screen.dart';
import 'screens/branch_blink/video_recording_screen.dart';
import 'screens/report_preview_screen.dart';
import 'screens/assistant_chat_screen.dart';
import 'screens/diagnosis_result_screen.dart';
import 'screens/new_ticket_screen.dart';
import 'models/support_ticket.dart';
import 'services/server_connectivity_service.dart';
import 'services/ticket_service.dart';
import 'services/auth_service.dart';
import 'models/diagnostic_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ServerConnectivityService.instance.initialize();
  await AuthService.instance.initialize();
  await DiagnosticState().loadUserProfile();
  await TicketService.instance.load();
  runApp(const RexhargeApp());
}

class RexhargeApp extends StatefulWidget {
  const RexhargeApp({super.key});

  @override
  State<RexhargeApp> createState() => _RexhargeAppState();
}

class _RexhargeAppState extends State<RexhargeApp> {
  final DiagnosticState _state = DiagnosticState();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EVision AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _state.darkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
      routes: {
        '/main': (context) => const MainShell(),
        '/settings': (context) => const SettingsScreen(),
        '/unified-detection': (context) => const OcrDetectionScreen(),
        '/charger-detection': (context) => const ChargerDetectionScreen(),
        '/isolator-detection': (context) => const IsolatorDetectionScreen(),
        '/evdb-detection': (context) => const EvdbDetectionScreen(),
        '/video-recording': (context) => const VideoRecordingScreen(),
        '/report': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return ReportPreviewScreen(
            errorCode: args is Map ? args['errorCode'] as String? : null,
            activityRecord: args is Map && args['activityRecord'] is Map<String, dynamic>
                ? args['activityRecord'] as Map<String, dynamic>
                : null,
          );
        },
        '/assistant': (context) => const AssistantChatScreen(),
        '/new-ticket': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return NewTicketScreen(prefill: TicketPrefill.fromRouteArgs(args));
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/diagnosis/')) {
          final errorCode = settings.name!.replaceFirst('/diagnosis/', '');
          final activityRecord = settings.arguments is Map<String, dynamic>
              ? settings.arguments as Map<String, dynamic>
              : null;
          return MaterialPageRoute(
            builder: (context) => DiagnosisResultScreen(
              errorCode: errorCode,
              activityRecord: activityRecord,
            ),
          );
        }
        return null;
      },
    );
  }
}
