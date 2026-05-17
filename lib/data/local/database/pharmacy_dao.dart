import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../../models/pharmacy_model.dart';

class PharmacyDao {
  Future<List<Pharmacy>> getAll() async {
    final db = await AppDatabase.database;
    final maps = await db.query('pharmacies');
    return maps.map((m) => Pharmacy.fromMap(m)).toList();
  }

  Future<void> insertAll(List<Pharmacy> pharmacies) async {
    final db = await AppDatabase.database;
    final batch = db.batch();
    for (final p in pharmacies) {
      batch.insert('pharmacies', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clear() async {
    final db = await AppDatabase.database;
    await db.delete('pharmacies');
  }
}
