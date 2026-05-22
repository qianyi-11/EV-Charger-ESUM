import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/glass_container.dart';
import '../../services/camera_session_manager.dart';

class RedLightBlinkingDetectionScreen extends StatefulWidget {
  const RedLightBlinkingDetectionScreen({super.key});

  @override
  State<RedLightBlinkingDetectionScreen> createState() => _RedLightBlinkingDetectionScreenState();
}

class _RedLightBlinkingDetectionScreenState extends State<RedLightBlinkingDetectionScreen>
    with TickerProviderStateMixin {
  final DiagnosticState _globalState = DiagnosticState();

  // Camera & Frame Processing
  CameraController? _cameraController;
  late CameraDescription _cameraDescription;
  Size? _previewSize; // Add this to track preview dimensions
  int _frameCount = 0;
  bool _isProcessing = false;
  bool _isRedOn = false; // Track current red state for transitions
  DateTime _lastTransition = DateTime.now(); // Track transition timing
  
  // ROI Detection
  Offset? _roiCenter;
  bool _roiSet = false;
  static const double roiSize = 60.0;
  static const double scanSize = 30.0;
  static const double roiLineWidth = 2.0;
  
  // Red Light State Tracking
  final List<bool> _stateHistory = []; // Last 50 ON/OFF states
  static const int maxHistoryLength = 50;
  int _transitionCount = 0;
  int _lastTransitionTime = 0;
  static const int debounceMs = 100;
  
  // Blinking Detection Result
  String _blinkingResult = "Detecting...";
  bool _isBlinkingDetected = false;
  bool _detectionComplete = false;
  
  // UI State
  String _instructionText = "Tap on the indicator light";
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _initializeCamera();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraDescription = cameras.first; // Back camera
      
      _cameraController = CameraController(
        _cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController?.initialize();
      // Wait for camera to stabilize before starting stream (Fix 1)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Capture preview size after init (Fix 4)
        _previewSize = _cameraController?.value.previewSize;
        if (kDebugMode) {
          debugPrint('[RedLight] Preview size: $_previewSize');
        }
        setState(() {});
        // Start frame processing
        _startFrameProcessing();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("[RedLightBlinking] Camera init error: $e");
      }
    }
  }

  void _startFrameProcessing() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      
      _frameCount++;
      // Process every frame for better responsiveness
      if (!_roiSet) return; // Don't process until ROI is set
      
      _isProcessing = true;
      try {
        final isLightOn = _detectRedLight(image);
        _updateBlinkingState(isLightOn);
      } catch (e) {
        if (kDebugMode) {
          debugPrint("[RedLightBlinking] Frame processing error: $e");
        }
      } finally {
        _isProcessing = false;
      }
    });
  }

  bool _detectRedLight(CameraImage image) {
    if (_roiCenter == null || image.planes.isEmpty) return false;
    
    try {
      final int width = image.width;
      final int height = image.height;

      // Fix 3: Scale ROI from preview coords to image coords (safer version)
      final double scaleX = _previewSize != null ? width / _previewSize!.width : 1.0;
      final double scaleY = _previewSize != null ? height / _previewSize!.height : 1.0;
      final int roiX = (_roiCenter!.dx * scaleX).toInt().clamp(32, width - 32);
      final int roiY = (_roiCenter!.dy * scaleY).toInt().clamp(32, height - 32);

      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      // Get actual row strides (important for Xiaomi/MediaTek devices)
      final int yRowStride = image.planes[0].bytesPerRow;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      int redPixelCount = 0;
      int totalPixels = 0;
      const int regionSize = 30;
      double sumR = 0, sumG = 0, sumB = 0;

      for (int dy = -regionSize; dy < regionSize; dy++) {
        for (int dx = -regionSize; dx < regionSize; dx++) {
          final int px = roiX + dx;
          final int py = roiY + dy;

          if (px < 0 || px >= width || py < 0 || py >= height) continue;

          final int yIndex = py * yRowStride + px;
          final int uvIndex = (py ~/ 2) * uvRowStride + (px ~/ 2) * uvPixelStride;

          if (yIndex >= yPlane.length || uvIndex >= uPlane.length || uvIndex >= vPlane.length) continue;

          final int yVal = yPlane[yIndex] & 0xFF;
          final int uVal = (uPlane[uvIndex] & 0xFF) - 128;
          final int vVal = (vPlane[uvIndex] & 0xFF) - 128;

          // Safer YUV→RGB conversion with proper coefficients
          final int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
          final int g = (yVal - 0.344 * uVal - 0.714 * vVal).round().clamp(0, 255);
          final int b = (yVal + 1.772 * uVal).round().clamp(0, 255);

          sumR += r;
          sumG += g;
          sumB += b;

          // Fix 2: Stricter red detection (r > 150 threshold)
          if (r > 150 && r > g * 1.5 && r > b * 1.5) {
            redPixelCount++;
          }
          totalPixels++;
        }
      }

      final double redRatio = totalPixels > 0 ? redPixelCount / totalPixels : 0;
      final double avgR = totalPixels > 0 ? sumR / totalPixels : 0;
      final double avgG = totalPixels > 0 ? sumG / totalPixels : 0;
      final double avgB = totalPixels > 0 ? sumB / totalPixels : 0;
      final bool isRedNow = redRatio > 0.3;

      // Fix 2: Debug print to verify RGB values
      if (_frameCount % 60 == 0) {
        debugPrint('DEBUG RGB at ROI(${roiX.toInt()},${roiY.toInt()}): r=${avgR.toInt()}, g=${avgG.toInt()}, b=${avgB.toInt()}');
        debugPrint('DEBUG redPixelCount=$redPixelCount / totalPixels=$totalPixels (ratio=${(redRatio*100).toStringAsFixed(1)}%)');
      }
      
      if (kDebugMode && _frameCount % 30 == 0) {
        debugPrint(
          '[RedLight] Frame: $_frameCount | redRatio=${redRatio.toStringAsFixed(2)} isRed=$isRedNow | '
          'Avg(R:${avgR.toStringAsFixed(0)},G:${avgG.toStringAsFixed(0)},B:${avgB.toStringAsFixed(0)})'
        );
      }

      return isRedNow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RedLight] Error in _detectRedLight: $e');
      }
      return false;
    }
  }

  void _updateBlinkingState(bool isLightOn) {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Add new state to history
    _stateHistory.add(isLightOn);
    if (_stateHistory.length > maxHistoryLength) {
      _stateHistory.removeAt(0);
    }
    
    // Check for state transitions with debouncing
    if (_stateHistory.length >= 2) {
      final currentState = _stateHistory.last;
      final previousState = _stateHistory[_stateHistory.length - 2];
      
      if (currentState != previousState) {
        // Transition detected
        if (now - _lastTransitionTime > debounceMs) {
          _transitionCount++;
          _lastTransitionTime = now;
          
          if (kDebugMode) {
            debugPrint("[RedLight] TRANSITION #$_transitionCount detected at sample ${_stateHistory.length}");
          }
        }
      }
    }
    
    // Determine blinking result
    bool shouldComplete = false;
    
    // Early completion: if we have at least 3 transitions, it's definitely blinking
    if (_transitionCount >= 3) {
      _isBlinkingDetected = true;
      _blinkingResult = "Blinking Detected";
      shouldComplete = true;
    }
    // After sufficient samples, check if blinking or not
    else if (_stateHistory.length >= maxHistoryLength) {
      if (_transitionCount >= 2) {
        _isBlinkingDetected = true;
        _blinkingResult = "Blinking Detected";
      } else if (_stateHistory.every((state) => state == _stateHistory.first)) {
        _isBlinkingDetected = false;
        _blinkingResult = "Not Blinking";
      } else {
        _blinkingResult = "Analyzing...";
      }
      shouldComplete = (_isBlinkingDetected || _blinkingResult == "Not Blinking");
    } else {
      _blinkingResult = "Analyzing... (${_stateHistory.length}/$maxHistoryLength)";
    }
    
    // Complete detection when we have a clear result
    if (shouldComplete && !_detectionComplete) {
      if (kDebugMode) {
        debugPrint("[RedLight] Detection complete: $_blinkingResult");
      }
      _completeDetection();
    }
  }

  void _completeDetection() {
    _detectionComplete = true;
    _cameraController?.stopImageStream();
    
    if (mounted) {
      setState(() {});
      
      // Navigate based on blinking detection result
      Timer(const Duration(milliseconds: 1500), () async {
        if (!mounted) return;
        
        _cameraController = null;
        await CameraSessionManager.instance.forceRelease();
        
        if (!mounted) return;
        
        if (_isBlinkingDetected) {
          // Blinking detected → go to 15s video recording
          _globalState.updateChargerInfo(true, true, "RED_BLINKING");
          Navigator.pushReplacementNamed(context, "/video-recording");
        } else {
          // No blinking → go to isolator detection
          _globalState.updateChargerInfo(true, false, "OFF");
          Navigator.pushReplacementNamed(context, "/isolator-detection");
        }
      });
    }
  }

  void _onScreenTap(Offset position) {
    if (_detectionComplete) return;
    
    setState(() {
      _roiCenter = position;
      _roiSet = true;
      _instructionText = "Tap again to reposition";
      _frameCount = 0; // Reset frame count when ROI is set
      _stateHistory.clear(); // Clear history for fresh detection
      _transitionCount = 0;
      _lastTransitionTime = 0;
    });
    
    if (kDebugMode) {
      debugPrint("[RedLight] ROI set at position: $position - Starting blinking detection");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen camera view as background
            if (_cameraController != null && _cameraController!.value.isInitialized)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            
            // Tap overlay
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) {
                  _onScreenTap(details.globalPosition);
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            
            // ROI Box overlay
            if (_roiSet && _roiCenter != null)
              Positioned(
                left: _roiCenter!.dx - roiSize / 2,
                top: _roiCenter!.dy - roiSize / 2,
                child: Container(
                  width: roiSize,
                  height: roiSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.yellow,
                      width: roiLineWidth,
                    ),
                  ),
                ),
              ),
            
            // Top Instruction Panel
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                      ),
                      child: Text(
                        _instructionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Status Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_roiSet)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.glassBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _blinkingResult,
                                  style: TextStyle(
                                    color: _isBlinkingDetected ? Colors.green : Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Transitions: $_transitionCount",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "Samples: ${_stateHistory.length}/$maxHistoryLength",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
