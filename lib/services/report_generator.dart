import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/diagnosis_report_data.dart';

class ReportGenerator {
  Future<Uint8List> generateDiagnosisPdfBytes(DiagnosisReportData report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'EVision Diagnostic Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Report ID: ${report.reportId}'),
          pw.Text(
            'Generated: ${report.generatedAt.toIso8601String().substring(0, 19).replaceFirst('T', ' ')}',
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Charger Specification Details'),
          _bulletRow('Brand', report.brand),
          _bulletRow('Model', report.model),
          _bulletRow('Serial Number', report.serialNumber),
          pw.SizedBox(height: 14),
          _sectionTitle('Diagnosis Result'),
          pw.Text('Fault type: ${report.faultType}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(report.headlineTitle,
              style: const pw.TextStyle(fontSize: 16)),
          if (report.headlineSubtitle != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(report.headlineSubtitle!),
          ],
          pw.SizedBox(height: 8),
          pw.Text('AI Confidence Score: ${report.confidencePercent}%'),
          pw.SizedBox(height: 14),
          _sectionTitle('Diagnostic Explanation'),
          pw.Text('Analysis findings:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          ...report.analysisFindings.map((item) => pw.Bullet(text: item)),
          pw.SizedBox(height: 14),
          _sectionTitle('Recommended Actions'),
          ...report.recommendedActions.map((item) => pw.Bullet(text: item)),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _bulletRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Future<File> saveDiagnosisPdf(DiagnosisReportData report) async {
    final bytes = await generateDiagnosisPdfBytes(report);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${report.reportId}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}
