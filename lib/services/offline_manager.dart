import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineManager {
  Database? _database;

  Future<void> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_reports.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE PendingReports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            serialNumber TEXT,
            modelName TEXT,
            faultType TEXT,
            actionDirective TEXT,
            confidenceScore REAL,
            pdfPath TEXT
          )
        ''');
      },
    );
  }

  Future<void> queueReport({
    required String timestamp,
    required String serialNumber,
    required String modelName,
    required String faultType,
    required String actionDirective,
    required double confidenceScore,
    required String pdfPath,
  }) async {
    if (_database == null) await initDatabase();

    await _database!.insert('PendingReports', {
      'timestamp': timestamp,
      'serialNumber': serialNumber,
      'modelName': modelName,
      'faultType': faultType,
      'actionDirective': actionDirective,
      'confidenceScore': confidenceScore,
      'pdfPath': pdfPath,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingReports() async {
    if (_database == null) await initDatabase();
    return await _database!.query('PendingReports');
  }

  Future<void> syncPendingReports() async {
    if (_database == null) await initDatabase();

    final pending = await getPendingReports();
    if (pending.isEmpty) return;

    // Simulated network sync process
    bool hasInternet = true; // In a real app, use connectivity_plus

    if (hasInternet) {
      for (var report in pending) {
        // TODO: Push to Firebase Firestore or custom backend here
        // e.g. await FirebaseFirestore.instance.collection('reports').add(report);
        
        // Remove from local queue on success
        await _database!.delete(
          'PendingReports',
          where: 'id = ?',
          whereArgs: [report['id']],
        );
      }
    }
  }
}
