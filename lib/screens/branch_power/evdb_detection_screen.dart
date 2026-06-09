import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic_state.dart';
import '../../widgets/camera_viewfinder.dart';
import '../../services/ml_model_service.dart';
import '../../services/camera_session_manager.dart';
import '../../services/integration_controller.dart';
import '../../services/sharp_capture.dart';
import '../../services/gallery_image_picker.dart';

enum EvdbPhase { scanning, analyzing, retake, result }

class EvdbDetectionScreen extends StatefulWidget {
  const EvdbDetectionScreen({super.key});

  @override
  State<EvdbDetectionScreen> createState() => _EvdbDetectionScreenState();
}

class _EvdbDetectionScreenState extends State<EvdbDetectionScreen> {
  EvdbPhase _phase = EvdbPhase.scanning;
  bool _showInstruction = true;
  bool _captureInFlight = false;
  bool _cameraReady = false;

  bool? _stepMcb;
  bool? _stepRccb;
  bool? _stepTypeA;
  bool? _stepSpecs;

  String? _retakeReason;
  EvdbResult? _lastResult;

  CameraController? _cameraController;
  final DiagnosticState _state = DiagnosticState();

  Future<void> _revealStep(void Function(bool?) setter, bool? value) async {
    if (!mounted) return;
    setState(() => setter(value));
    await Future.delayed(const Duration(milliseconds: 350));
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
      _phase = EvdbPhase.analyzing;
    });

    try {
      final photo = await SharpCapture.takePicture(_cameraController!);
      await _processImage(photo);
    } catch (e) {
      if (mounted) {
        setState(() => _phase = EvdbPhase.scanning);
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
      _phase = EvdbPhase.analyzing;
    });

    try {
      final photo = await GalleryImagePicker.pick();
      if (!mounted) return;
      if (photo == null) {
        setState(() => _phase = EvdbPhase.scanning);
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
      _phase = EvdbPhase.analyzing;
      _stepMcb = null;
      _stepRccb = null;
      _stepTypeA = null;
      _stepSpecs = null;
      _retakeReason = null;
    });

    try {
      final mlService = MlModelService();
      final result = await mlService.processEvdbFrame(photo);

      if (!mounted) return;

      if (kDebugMode) {
        debugPrint(
          '[EvdbDetect] compliant=${result.isCompliant} retake=${result.retakeRequired} '
          'mcb=${result.mcbDetected} rccb=${result.rccbDetected} typeA=${result.typeADetected} '
          'issues=${result.issues}',
        );
      }

      _lastResult = result;

      if (!result.success && !result.retakeRequired) {
        setState(() {
          _phase = EvdbPhase.retake;
          _retakeReason = result.errorMessage ?? 'EVDB analysis failed. Please retake.';
        });
        return;
      }

      await _revealStep((v) => _stepMcb = v, result.mcbDetected);
      if (!mounted) return;
      await _revealStep((v) => _stepRccb = v, result.rccbDetected);
      if (!mounted) return;
      await _revealStep((v) => _stepTypeA = v, result.typeADetected);

      final specsPass = result.isCompliant &&
          !result.retakeRequired &&
          result.mcbDetected &&
          result.rccbDetected;
      await _revealStep((v) => _stepSpecs = v, specsPass);
      if (!mounted) return;

      if (result.retakeRequired) {
        setState(() {
          _phase = EvdbPhase.retake;
          _retakeReason = result.retakeReason ??
              result.errorMessage ??
              'Photo is not clear enough. Please retake.';
        });
        return;
      }

      _state.setPowerBranchOutcomes(
        isolatorOn: _state.isIsolatorOn,
        evdbOk: result.isCompliant,
      );

      if (!result.isCompliant) {
        final errorCode = result.errorCode ?? 'protection-issue';
        final findings = result.issues.isNotEmpty
            ? result.issues
            : [
                if (!result.mcbDetected) 'MCB missing — not detected in EVDB image.',
                if (!result.rccbDetected) 'RCCB missing — not detected in EVDB image.',
                if (!result.typeADetected) 'Type A symbol not detected on RCCB.',
                if (result.errorMessage != null && result.errorMessage!.isNotEmpty)
                  result.errorMessage!,
              ];

        _state.setFaultsFromEvdbAnalysis(
          mcbDetected: result.mcbDetected,
          rccbDetected: result.rccbDetected,
          issues: findings,
          confidence: result.confidence,
        );
        _state.addDiagnosticRecord(errorCode);

        setState(() => _phase = EvdbPhase.result);
        await Future.delayed(const Duration(milliseconds: 1800));
        if (!mounted) return;
        await _goToDiagnosis(errorCode);
        return;
      }

      _state.clearScanFindings();
      setState(() => _phase = EvdbPhase.result);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final integration = IntegrationController();
      final decision = await integration.processDiagnosticsAndRoute(
        isChargerDead: true,
        isIsolatorOff: false,
        isMcbMissingOrWrong: false,
        isSolidRedLight: false,
        flashCount: 0,
      );
      _state.setFaultsFromSupplyIssue(confidence: 0.92);
      await _goToDiagnosis(decision.errorCode);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EvdbDetect] error: $e');
      }
      if (mounted) {
        setState(() {
          _phase = EvdbPhase.retake;
          _retakeReason = 'Analysis failed: $e';
        });
      }
    }
  }

  Future<void> _goToDiagnosis(String errorCode) async {
    _cameraController = null;
    await CameraSessionManager.instance.forceRelease();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/diagnosis/$errorCode');
  }

  void _retryCapture() {
    setState(() {
      _phase = EvdbPhase.scanning;
      _retakeReason = null;
      _captureInFlight = false;
      _cameraReady = false;
      _stepMcb = null;
      _stepRccb = null;
      _stepTypeA = null;
      _stepSpecs = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_phase == EvdbPhase.scanning)
            CameraViewfinder(
              fillScreen: true,
              highQualityCapture: true,
              forceNewSession: true,
              onControllerCreated: (c) => _cameraController = c,
              onReady: () {
                if (mounted) setState(() => _cameraReady = true);
              },
              fallbackBuilder: (context) => Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: const Text(
                  'Camera unavailable.\nCheck permissions and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              overlay: const SizedBox.shrink(),
            )
          else
            ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
              child: Container(color: Colors.blueGrey.shade900),
            ),

          if (_phase == EvdbPhase.scanning)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              bottom: _showInstruction ? 168 : -200,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.electricBlue.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.electrical_services, color: AppColors.electricBlue, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Capture or upload a clear photo of the EVDB showing MCB and RCCB breakers.',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    if (_state.inputVoltage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Spec plate voltage: ${_state.inputVoltage}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          if (_phase == EvdbPhase.scanning)
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
                              ? 'Capture EVDB Photo'
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

          if (_phase == EvdbPhase.analyzing || _phase == EvdbPhase.retake || _phase == EvdbPhase.result)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
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
                        if (_phase == EvdbPhase.analyzing)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricBlue),
                            ),
                          )
                        else if (_phase == EvdbPhase.retake)
                          const Icon(Icons.refresh, color: AppColors.warningOrange, size: 20)
                        else if (_lastResult?.isCompliant == true)
                          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20)
                        else
                          const Icon(Icons.error, color: AppColors.dangerRed, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _phase == EvdbPhase.analyzing
                              ? 'Analyzing EVDB...'
                              : _phase == EvdbPhase.retake
                                  ? 'Retake Required'
                                  : _lastResult?.isCompliant == true
                                      ? 'EVDB Compliant'
                                      : 'Protection Issue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _checkItem('MCB presence check', _stepMcb),
                    const SizedBox(height: 8),
                    _checkItem('RCCB presence check', _stepRccb),
                    const SizedBox(height: 8),
                    _checkItem('Type A symbol check', _stepTypeA),
                    const SizedBox(height: 8),
                    _checkItem('Spec compliance (phase & voltage)', _stepSpecs),
                    if (_phase == EvdbPhase.retake) ...[
                      const SizedBox(height: 16),
                      Text(
                        _retakeReason ?? 'Please retake a clearer photo.',
                        style: const TextStyle(color: AppColors.warningOrange, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _retryCapture,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    if (_phase == EvdbPhase.result && _lastResult?.isCompliant == false) ...[
                      const SizedBox(height: 12),
                      ..._lastResult!.issues.take(4).map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $issue', style: const TextStyle(color: AppColors.dangerRed, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Routing to Protection Issue diagnosis...',
                        style: TextStyle(color: AppColors.dangerRed, fontSize: 13),
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

  Widget _checkItem(String label, bool? passed) {
    final IconData icon;
    final Color color;
    if (passed == null) {
      icon = Icons.check_box_outline_blank;
      color = Colors.white24;
    } else if (passed) {
      icon = Icons.check_box;
      color = AppColors.successGreen;
    } else {
      icon = Icons.cancel;
      color = AppColors.dangerRed;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: passed == null ? Colors.white54 : Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
