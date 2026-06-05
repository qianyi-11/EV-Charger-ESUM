import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/diagnostic_state.dart';
import '../widgets/glass_container.dart';
import '../services/firebase_service.dart';

class DiagnosisResultScreen extends StatefulWidget {
  final String errorCode;

  const DiagnosisResultScreen({super.key, required this.errorCode});

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> with TickerProviderStateMixin {
  final DiagnosticState _globalState = DiagnosticState();
  
  // Simulated auto contact state
  bool _isContacting = true;
  Timer? _contactTimer;

  // Firebase Sync State
  bool _isSyncing = true;
  String? _syncError;

  // AI confidence animator
  double _animatedConfidence = 0.0;
  late final AnimationController _confidenceController;

  @override
  void initState() {
    super.initState();
    
    // Trigger Firebase Telemetry Sync in background
    _syncTelemetry();
    
    final info = _globalState.database[widget.errorCode] ?? _globalState.database["charger-issue"]!;
    final displayConfidence = _globalState.scanConfidence > 0
        ? _globalState.scanConfidence
        : info.confidence;

    if (info.autoContact) {
      _isContacting = true;
      _contactTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isContacting = false;
          });
        }
      });
    } else {
      _isContacting = false;
    }

    // AI Confidence score animation
    _confidenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    final Animation<double> curve = CurvedAnimation(parent: _confidenceController, curve: Curves.easeOutCubic);
    
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confidenceController.forward();
      }
    });

    _confidenceController.addListener(() {
      setState(() {
        _animatedConfidence = curve.value * displayConfidence;
      });
    });
  }

  List<String> _displayFindings(DiagnosisInfo info) {
    if (_globalState.scanFindings.isNotEmpty) {
      return _globalState.scanFindings;
    }
    return info.findings;
  }

  @override
  void dispose() {
    _contactTimer?.cancel();
    _confidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _globalState.database[widget.errorCode] ?? _globalState.database["charger-issue"]!;
    
    Color severityColor = AppColors.successGreen;
    IconData severityIcon = Icons.check_circle;
    String severityLabel = "INFO";

    if (info.severity == DiagnosisSeverity.critical) {
      severityColor = AppColors.dangerRed;
      severityIcon = Icons.warning_amber_rounded;
      severityLabel = "CRITICAL";
    } else if (info.severity == DiagnosisSeverity.warning) {
      severityColor = AppColors.warningOrange;
      severityIcon = Icons.error_outline;
      severityLabel = "WARNING";
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("AI Fault Diagnosis"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Firebase Sync Status Banner
              _buildSyncStatusBanner(),
              const SizedBox(height: 16),

              // 1. Auto-contact Notification Banner
              if (info.autoContact) ...[
                _buildTechnicianBanner(severityColor),
                const SizedBox(height: 16),
              ],

              // 2. Main Diagnosis Result Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderColor: severityColor.withOpacity(0.25),
                child: Stack(
                  children: [
                    // Glow blob background in corner
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: severityColor.withOpacity(0.06),
                              blurRadius: 40,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: severityColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(severityIcon, color: severityColor, size: 12),
                                  const SizedBox(width: 6),
                                  Text(
                                    severityLabel,
                                    style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "Confidence: ${(_animatedConfidence * 100).toInt()}%",
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Error code heading
                        Text(
                          info.code,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          info.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.subTitle,
                          style: const TextStyle(color: AppColors.electricBlue, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 14),
                        
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 8),

                        Text(
                          info.description,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. AI Confidence Meter
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("AI Inference Precision:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 8,
                              child: LinearProgressIndicator(
                                value: _animatedConfidence,
                                backgroundColor: Colors.white12,
                                color: _animatedConfidence < 0.6
                                    ? AppColors.dangerRed
                                    : _animatedConfidence < 0.85
                                        ? AppColors.warningOrange
                                        : AppColors.successGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          "${(_animatedConfidence * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Diagnostic Explanation Section
              GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.electricBlue, size: 18),
                        SizedBox(width: 8),
                        Text("Diagnostic Explanation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _globalState.scanFindings.isNotEmpty
                          ? "EVDB scan findings from your photo:"
                          : "Analysis findings & circuit telemetry diagnostics:",
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      _displayFindings(info).length,
                      (index) => _buildCheckBulletItem(_displayFindings(info)[index], index),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Recommended Actions Section
              GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.electricBlue, size: 18),
                        SizedBox(width: 8),
                        Text("Recommended Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section A: Immediate Actions
                    const Text("IMMEDIATE USER ACTIONS:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.electricBlue, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ...List.generate(
                      info.immediateActions.length,
                      (index) => _buildActionBulletItem(info.immediateActions[index], index),
                    ),
                    const SizedBox(height: 20),

                    // Section B: Technical Investigation
                    const Text("TECHNICAL INVESTIGATION:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.warningOrange, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ...List.generate(
                      info.technicalActions.length,
                      (index) => _buildActionBulletItem(info.technicalActions[index], index),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Navigation / Diagnostic Grid Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionGridButton(
                      title: "Generate Report",
                      icon: Icons.file_copy_outlined,
                      onTap: () => Navigator.pushNamed(context, "/report"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionGridButton(
                      title: "Ask EVision AI",
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => Navigator.pushNamed(context, "/assistant"),
                    ),
                  ),
                ],
              ),
              
              if (!info.autoContact) ...[
                const SizedBox(height: 12),
                _buildActionGridButton(
                  title: "Share with Service Technician",
                  icon: Icons.share_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Diagnostic data copied to clipboard. Ready to share."),
                        backgroundColor: AppColors.secondaryBg,
                      ),
                    );
                  },
                  isFullWidth: true,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianBanner(Color color) {
    if (_isContacting) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderColor: AppColors.electricBlue.withOpacity(0.3),
        bgColor: AppColors.electricBlue.withOpacity(0.05),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricBlue),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Contacting Support...",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Transmitting telemetric data report to after-sales support systems...",
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Contacted
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, val, child) {
        return Transform.scale(
          scale: 0.95 + (val * 0.05),
          child: Opacity(
            opacity: val,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderColor: AppColors.successGreen.withOpacity(0.3),
              bgColor: AppColors.successGreen.withOpacity(0.05),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.black, size: 14),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Support Dispatched",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Full diagnostic metrics successfully synchronized. Technical team has been notified.",
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text("SENT", style: TextStyle(color: AppColors.successGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckBulletItem(String text, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.radio_button_checked, color: AppColors.electricBlue, size: 10),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBulletItem(String text, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Icons.circle, color: AppColors.electricBlue, size: 6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGridButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GlassContainer(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.electricBlue, size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncTelemetry() async {
    try {
      final docId = await FirebaseService().saveScanResult(_globalState);
      _globalState.setSavedReportId(docId);
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    } catch (e) {
      debugPrint("Telemetry sync failed: $e");
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncError = e.toString();
        });
      }
    }
  }

  Widget _buildSyncStatusBanner() {
    if (_isSyncing) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderColor: AppColors.electricBlue.withOpacity(0.3),
        bgColor: AppColors.electricBlue.withOpacity(0.05),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricBlue),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Syncing diagnostic telemetry to Firestore...",
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_syncError != null) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderColor: AppColors.dangerRed.withOpacity(0.3),
        bgColor: AppColors.dangerRed.withOpacity(0.05),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: AppColors.dangerRed, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Offline Mode: Sync failed or cached offline",
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: AppColors.successGreen.withOpacity(0.4),
      bgColor: AppColors.successGreen.withOpacity(0.03),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_done, color: AppColors.successGreen, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cloud Synced",
                  style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "Telemetry ID: ${_globalState.savedReportId}",
                  style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: "Courier"),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text("LIVE", style: TextStyle(color: AppColors.successGreen, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
