import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/diagnostic_state.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Upsert registered / logged-in user profile to Firestore `users` collection.
  Future<void> saveUserProfile(AppUserProfile profile) async {
    try {
      await _db.collection('users').doc(profile.uid).set(
        {
          ...profile.toFirestore(),
          'displayName': profile.displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error saving user profile to Firestore: $e');
    }
  }

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
