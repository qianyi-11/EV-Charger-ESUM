import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';

class CameraViewfinder extends StatefulWidget {
  final Widget Function(BuildContext)? fallbackBuilder;
  final Widget? overlay;
  final double aspectRatio;
  final Function(CameraController)? onControllerCreated;

  const CameraViewfinder({
    super.key,
    this.fallbackBuilder,
    this.overlay,
    this.aspectRatio = 4 / 3,
    this.onControllerCreated,
  });

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changes (background/foreground) require releasing/re-initializing the camera
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = "No camera hardware detected.";
        });
        return;
      }

      final controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;

      await controller.initialize();
      
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      if (widget.onControllerCreated != null) {
        widget.onControllerCreated!(controller);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to access camera: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || !_isInitialized || _controller == null) {
      // Fallback builder (e.g. blueprint animations for web/PC previewing)
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
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : "Initializing video stream...",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Active Live Native Camera Stream
            CameraPreview(_controller!),
            
            // Standard crosshair/grid custom drawing inside viewfinder
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      ),
    );
  }
}
