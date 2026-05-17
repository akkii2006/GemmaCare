import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../../models/hospital_model.dart';

class HospitalDao {
  Future<List<Hospital>> getAll() async {
    final db = await AppDatabase.database;
    final maps = await db.query('hospitals');
    return maps.map((m) => Hospital.fromMap(m)).toList();
  }

  Future<void> insertAll(List<Hospital> hospitals) async {
    final db = await AppDatabase.database;
    final batch = db.batch();
    for (final h in hospitals) {
      batch.insert('hospitals', h.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clear() async {
    final db = await AppDatabase.database;
    await db.delete('hospitals');
  }
}
