import 'package:sqflite/sqflite.dart';
import '../local/database/app_database.dart';
import '../models/appointment_model.dart';

class AppointmentRepository {
  Future<List<Appointment>> getAll() async {
    final db = await AppDatabase.database;
    final maps = await db.query('appointments', orderBy: 'dateTime DESC');
    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<List<Appointment>> getUpcoming() async {
    final db = await AppDatabase.database;
    final maps = await db.query('appointments', where: 'isUpcoming = 1', orderBy: 'dateTime ASC');
    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<List<Appointment>> getPast() async {
    final db = await AppDatabase.database;
    final maps = await db.query('appointments', where: 'isUpcoming = 0', orderBy: 'dateTime DESC');
    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<int> insert(Appointment appointment) async {
    final db = await AppDatabase.database;
    return db.insert('appointments', appointment.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.database;
    await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> update(Appointment appointment) async {
    final db = await AppDatabase.database;
    await db.update('appointments', appointment.toMap(), where: 'id = ?', whereArgs: [appointment.id]);
  }
}
