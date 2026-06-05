import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../services/camera_session_manager.dart';

class CameraViewfinder extends StatefulWidget {
  final Widget Function(BuildContext)? fallbackBuilder;
  final Widget? overlay;
  final double aspectRatio;
  final Function(CameraController)? onControllerCreated;
  final bool fillScreen;
  final bool forVideo;
  /// High resolution + fresh session for still captures (OCR, EVDB, isolator).
  final bool highQualityCapture;
  /// Discard any existing session and open a new high-quality camera.
  final bool forceNewSession;
  /// Called when the camera preview is initialized and ready to capture.
  final VoidCallback? onReady;

  const CameraViewfinder({
    super.key,
    this.fallbackBuilder,
    this.overlay,
    this.aspectRatio = 4 / 3,
    this.onControllerCreated,
    this.onReady,
    this.fillScreen = false,
    this.forVideo = false,
    this.highQualityCapture = false,
    this.forceNewSession = false,
  });

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = "";
  bool _ownsSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsSession) {
      CameraSessionManager.instance.release();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      CameraSessionManager.instance.forceRelease();
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _ownsSession = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isInitialized) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final controller = await CameraSessionManager.instance.acquire(
        forVideo: widget.forVideo,
        highQuality: widget.highQualityCapture,
        forceNew: widget.forceNewSession,
      );
      _controller = controller;
      _ownsSession = true;

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      widget.onControllerCreated?.call(controller);
      widget.onReady?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to access camera: $e";
        });
      }
    }
  }

  Widget _buildOfflineState() {
    if (widget.fallbackBuilder != null) {
      return widget.fallbackBuilder!(context);
    }

    return Container(
      color: Colors.black.withOpacity(0.85),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.videocam_off,
              color: AppColors.electricBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Viewfinder Offline",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage.isNotEmpty ? _errorMessage : "Initializing video stream...",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final preview = FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.previewSize?.height ?? 1,
        height: _controller!.value.previewSize?.width ?? 1,
        child: CameraPreview(_controller!),
      ),
    );

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        preview,
        if (widget.overlay != null) widget.overlay!,
      ],
    );

    if (widget.fillScreen) {
      return stack;
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: stack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || !_isInitialized || _controller == null) {
      return _buildOfflineState();
    }
    return _buildPreview();
  }
}
