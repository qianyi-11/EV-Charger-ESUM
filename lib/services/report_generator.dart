import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class DiagnosticReport {
  final String timestamp;
  final String serialNumber;
  final String modelName;
  final String faultType;
  final String actionDirective;
  final double confidenceScore;
  final File? screenshot;

  DiagnosticReport({
    required this.timestamp,
    required this.serialNumber,
    required this.modelName,
    required this.faultType,
    required this.actionDirective,
    required this.confidenceScore,
    this.screenshot,
  });
}

class ReportGenerator {
  Future<File> generateDiagnosticPdf(DiagnosticReport report) async {
    final pdf = pw.Document();

    pw.Widget? imageWidget;
    if (report.screenshot != null && await report.screenshot!.exists()) {
      final imageBytes = await report.screenshot!.readAsBytes();
      final image = pw.MemoryImage(imageBytes);
      imageWidget = pw.Image(image, width: 300);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Diagnostic Observation Report")),
              pw.SizedBox(height: 20),
              pw.Text("Timestamp: ${report.timestamp}"),
              pw.Text("Model: ${report.modelName}"),
              pw.Text("Serial Number: ${report.serialNumber}"),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Fault Detected: ${report.faultType}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text("Action Directive: ${report.actionDirective}"),
              pw.Text("AI Confidence: ${(report.confidenceScore * 100).toStringAsFixed(1)}%"),
              pw.SizedBox(height: 20),
              if (imageWidget != null) ...[
                pw.Text("Screenshot / Observation Evidence:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                imageWidget,
              ] else ...[
                pw.Text("No screenshot evidence provided."),
              ],
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Diagnostic_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
