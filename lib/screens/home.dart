import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, String>> _scanHistory = const [
    {
      'title': 'Error 8 - RCCB Fault',
      'subtitle': 'Residual current detected in the charging circuit',
      'time': '2 hours ago',
      'status': 'critical',
      'route': '/diagnosis/blink-8',
    },
    {
      'title': 'Error 3 - Ground Fault',
      'subtitle': 'Earth conductor imbalance observed',
      'time': '1 day ago',
      'status': 'warning',
      'route': '/diagnosis/ground-fault',
    },
    {
      'title': 'System OK',
      'subtitle': 'No active faults in the last scan',
      'time': '2 days ago',
      'status': 'success',
      'route': '/diagnosis/system-ok',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020817),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          children: [
            // Header
            FadeInDown(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Welcome to EVision AI",
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings, color: Colors.cyan),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions Grid
            FadeIn(
              delay: const Duration(milliseconds: 100),
              child: Row(
                children: [
                  _buildQuickAction(
                    context: context,
                    icon: Icons.camera_alt,
                    title: "Start\nDiagnosis", // Split to fit mobile screens
                    color: Colors.cyan,
                    route: '/unified-detection',
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: "AI\nAssistant",
                    color: const Color(0xFF00FF88),
                    route: '/assistant',
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context: context,
                    icon: Icons.description,
                    title: "View\nReports",
                    color: Colors.orange,
                    route: '/report',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // System Status
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.show_chart, color: Colors.cyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "System Status",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatusCard("AI Model", "v2.4.1"),
                      const SizedBox(width: 12),
                      _buildStatusCard("Detection Rate", "98.5%"),
                      const SizedBox(width: 12),
                      _buildStatusCard("Speed", "45ms"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Recent Activity
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, color: Colors.cyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Recent Activity",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._scanHistory.map(
                    (scan) => Column(
                      children: [
                        _buildActivityRow(
                          context,
                          scan['title']!,
                          scan['subtitle']!,
                          scan['time']!,
                          scan['status']!,
                          scan['route']!,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Quick Actions
  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required String route,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.3), blurRadius: 20),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for System Status Cards
  Widget _buildStatusCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF88),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Recent Activity List
  Widget _buildActivityRow(
    BuildContext context,
    String error,
    String subtitle,
    String time,
    String status,
    String route,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case "critical":
        statusColor = const Color(0xFFFF2D55); // Red
        statusIcon = Icons.warning_amber_rounded;
        break;
      case "warning":
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case "success":
      default:
        statusColor = const Color(0xFF00FF88); // Green
        statusIcon = Icons.check_circle;
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
