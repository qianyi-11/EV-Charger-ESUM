import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/ml_model_service.dart';
import '../../services/camera_session_manager.dart';
import '../../services/sharp_capture.dart';
import '../../services/gallery_image_picker.dart';

enum IsolatorPhase { scanning, analyzing, resultOff, resultOn }

class IsolatorDetectionScreen extends StatefulWidget {
  const IsolatorDetectionScreen({super.key});

  @override
  State<IsolatorDetectionScreen> createState() => _IsolatorDetectionScreenState();
}

class _IsolatorDetectionScreenState extends State<IsolatorDetectionScreen> {
  IsolatorPhase _phase = IsolatorPhase.scanning;
  bool _showInstruction = true;
  bool _captureInFlight = false;
  bool _cameraReady = false;

  bool _step1Done = false;
  bool _step2Done = false;
  bool? _switchOn;

  CameraController? _cameraController;
  final DiagnosticState _state = DiagnosticState();

  @override
  void dispose() {
    _cameraController = null;
    super.dispose();
  }

  void _notifyCameraNotReady() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera is still starting — please wait a moment.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _captureAndAnalyze() async {
    if (_captureInFlight) return;
    if (!_cameraReady ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      _notifyCameraNotReady();
      return;
    }

    setState(() {
      _captureInFlight = true;
      _phase = IsolatorPhase.analyzing;
    });

    try {
      final photo = await SharpCapture.takePicture(_cameraController!);
      await _processImage(photo);
    } catch (e) {
      if (mounted) {
        setState(() => _phase = IsolatorPhase.scanning);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _captureInFlight = false);
    }
  }

  Future<void> _pickFromGalleryAndAnalyze() async {
    if (_captureInFlight) return;

    setState(() {
      _captureInFlight = true;
      _phase = IsolatorPhase.analyzing;
    });

    try {
      final photo = await GalleryImagePicker.pick();
      if (!mounted) return;
      if (photo == null) {
        setState(() => _phase = IsolatorPhase.scanning);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
        return;
      }
      await _processImage(photo);
    } finally {
      if (mounted) setState(() => _captureInFlight = false);
    }
  }

  Future<void> _processImage(XFile photo) async {
    setState(() {
      _step1Done = false;
      _step2Done = false;
      _switchOn = null;
    });

    try {
      final mlService = MlModelService();
      final result = await mlService.processIsolatorFrame(photo);

      if (!mounted) return;

      if (kDebugMode) {
        debugPrint(
          '[IsolatorDetect] success=${result.success} detected=${result.isolatorDetected} '
          'on=${result.isSwitchOn} method=${result.method} err=${result.errorMessage}',
        );
      }

      if (!result.success) {
        setState(() => _phase = IsolatorPhase.scanning);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  'Isolator detection failed. Retake with the switch clearly visible.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() => _step1Done = result.isolatorDetected);

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      final isOn = result.isSwitchOn;
      _state.setPowerBranchOutcomes(
        isolatorOn: isOn,
        evdbOk: _state.isEvdbOk,
      );

      setState(() {
        _step2Done = true;
        _switchOn = isOn;
        _phase = isOn ? IsolatorPhase.resultOn : IsolatorPhase.resultOff;
      });

      if (isOn) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        await _navigateToEvdb();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[IsolatorDetect] analyze error: $e');
      }
      if (mounted) {
        setState(() => _phase = IsolatorPhase.scanning);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Isolator detection failed: $e')),
        );
      }
    }
  }

  Future<void> _navigateToEvdb() async {
    _cameraController = null;
    await CameraSessionManager.instance.forceRelease();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/evdb-detection");
  }

  void _showIsolatorExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text("Isolator Switch Example", style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          height: 200,
          color: Colors.white10,
          child: const Center(
            child: Icon(Icons.power, color: AppColors.electricBlue, size: 80),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it", style: TextStyle(color: AppColors.electricBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_phase == IsolatorPhase.scanning)
            CameraViewfinder(
              fillScreen: true,
              highQualityCapture: true,
              forceNewSession: true,
              onControllerCreated: (controller) => _cameraController = controller,
              onReady: () {
                if (mounted) setState(() => _cameraReady = true);
              },
              fallbackBuilder: (context) => Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off, color: AppColors.electricBlue, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Camera unavailable.\nCheck permissions and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              overlay: const SizedBox.shrink(),
            )
          else
            ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
              child: Container(color: Colors.blueGrey.shade900),
            ),

          if (_phase == IsolatorPhase.scanning)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              bottom: _showInstruction ? 168 : -200,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warningOrange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warningOrange, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Point your camera at the isolator switch, or upload a photo from your gallery.",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: AppColors.electricBlue),
                      onPressed: () => _showIsolatorExample(context),
                    ),
                  ],
                ),
              ),
            ),

          if (_phase == IsolatorPhase.scanning)
            Positioned(
              left: 24,
              right: 24,
              bottom: 36,
              child: Material(
                color: Colors.transparent,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: (_captureInFlight || !_cameraReady) ? null : _captureAndAnalyze,
                    icon: _captureInFlight
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.black),
                    label: Text(
                      _captureInFlight
                          ? 'Capturing...'
                          : _cameraReady
                              ? 'Capture Isolator Photo'
                              : 'Starting camera...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _captureInFlight ? null : _pickFromGalleryAndAnalyze,
                    icon: const Icon(Icons.photo_library_outlined, color: AppColors.electricBlue),
                    label: const Text(
                      'Upload from Gallery',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.electricBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              ),
            ),

          if (_phase != IsolatorPhase.scanning)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_phase == IsolatorPhase.analyzing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricBlue),
                            ),
                          )
                        else if (_phase == IsolatorPhase.resultOn)
                          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20)
                        else
                          const Icon(Icons.error, color: AppColors.dangerRed, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _phase == IsolatorPhase.analyzing
                              ? 'Analyzing Isolator...'
                              : _phase == IsolatorPhase.resultOn
                                  ? 'Analysis Complete'
                                  : 'Isolator OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildChecklistItem('Isolator detected', _step1Done, null),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      'Switch position: ${!_step2Done ? '...' : (_switchOn == true ? 'ON' : 'OFF')}',
                      _step2Done,
                      _step2Done
                          ? (_switchOn == true ? AppColors.successGreen : AppColors.dangerRed)
                          : null,
                    ),
                    if (_phase == IsolatorPhase.resultOff) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text(
                        'Please flip the isolator switch to the ON position, then capture again.',
                        style: TextStyle(color: AppColors.warningOrange, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _phase = IsolatorPhase.scanning);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                          ),
                          child: const Text(
                            'Capture Again',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            _state.setPowerBranchOutcomes(isolatorOn: true, evdbOk: _state.isEvdbOk);
                            await _navigateToEvdb();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                          ),
                          child: const Text('I have turned it ON'),
                        ),
                      ),
                    ],
                    if (_phase == IsolatorPhase.resultOn) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Power confirmed at isolator.\nProceeding to EVDB check...',
                        style: TextStyle(color: AppColors.successGreen, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label, bool isDone, Color? overrideColor) {
    return Row(
      children: [
        if (isDone)
          Icon(Icons.check_box, color: overrideColor ?? AppColors.successGreen, size: 20)
        else
          const Icon(Icons.check_box_outline_blank, color: Colors.white24, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDone ? (overrideColor ?? Colors.white) : Colors.white54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
