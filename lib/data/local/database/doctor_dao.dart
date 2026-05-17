import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../../models/doctor_model.dart';

class DoctorDao {
  Future<List<Doctor>> getAll() async {
    final db = await AppDatabase.database;
    final maps = await db.query('doctors');
    return maps.map((m) => Doctor.fromMap(m)).toList();
  }

  Future<int> insert(Doctor doctor) async {
    final db = await AppDatabase.database;
    return db.insert('doctors', doctor.toMap());
  }

  Future<void> insertAll(List<Doctor> doctors) async {
    final db = await AppDatabase.database;
    final batch = db.batch();
    for (final d in doctors) {
      batch.insert('doctors', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clear() async {
    final db = await AppDatabase.database;
    await db.delete('doctors');
  }
}
