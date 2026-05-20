import 'package:flutter/material.dart';

// Import your custom theme and widgets
import 'theme/app_colors.dart';
import 'widgets/glass_card.dart';

// Import all your screens
import 'screens/splash.dart';
import 'screens/home.dart';
import 'screens/unified_detection.dart';
import 'screens/photo_isolator.dart';
import 'screens/photo_evdb.dart';
import 'screens/video_recording.dart';
import 'screens/diagnostic_result_new.dart';
import 'screens/ai_assistant.dart';
import 'screens/report_preview.dart';
import 'screens/settings.dart';

void main() {
  runApp(const EVisionApp());
}

class EVisionApp extends StatelessWidget {
  const EVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EVision AI',
      debugShowCheckedModeBanner: false,
      // Removed 'const' here because AppColors are evaluated at runtime
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.danger,
          surface: AppColors.muted,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: AppColors.foreground),
          displayLarge: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/unified-detection': (context) => const UnifiedDetectionScreen(),
        '/photo-isolator': (context) => const PhotoIsolatorScreen(),
        '/photo-evdb': (context) => const PhotoEVDBScreen(),
        '/video-recording': (context) => const VideoRecordingScreen(),
        '/assistant': (context) => const AIAssistantScreen(),
        '/report': (context) => const ReportPreviewScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/diagnosis/')) {
          final errorCode = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => DiagnosisResultNewScreen(errorCode: errorCode),
          );
        }
        return null;
      },
    );
  }
}

// Utility widget remains here for easy access
class ImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final String? altText;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ImageWithFallback({
    super.key,
    required this.imageUrl,
    this.altText,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width ?? 88,
          height: height ?? 88,
          color: Colors.grey[900],
          alignment: Alignment.center,
          child: Tooltip(
            message: altText ?? 'Error loading image',
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white30,
              size: (width != null && width! < 40) ? 20 : 36,
            ),
          ),
        );
      },
    );
  }
}