import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diagnostic_state.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save diagnostic scan details to the 'scans' collection
  Future<String> saveScanResult(DiagnosticState state) async {
    try {
      final info = state.database[state.targetErrorCode];
      
      final Map<String, dynamic> data = {
        'chargerModel': state.chargerModel,
        'serialNumber': state.serialNumber,
        'selectedBranch': state.selectedBranch,
        'isIsolatorOn': state.isIsolatorOn,
        'isEvdbOk': state.isEvdbOk,
        'blinksCounted': state.blinksCounted,
        'targetErrorCode': state.targetErrorCode,
        'diagnosisCode': info?.code ?? 'GEN-001',
        'diagnosisName': info?.name ?? 'General Charger Fault',
        'diagnosisSubtitle': info?.subTitle ?? 'Hardware Anomaly',
        'severity': info?.severity.name ?? 'warning',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add to scans collection
      final docRef = await _db.collection('scans').add(data);
      return docRef.id;
    } catch (e) {
      print("Error saving telemetry to Firestore: $e");
      rethrow;
    }
  }

  // Get a single diagnostic record from the 'scans' collection
  Future<Map<String, dynamic>?> getScanResult(String documentId) async {
    try {
      final doc = await _db.collection('scans').doc(documentId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print("Error reading telemetry from Firestore: $e");
      rethrow;
    }
  }
}
