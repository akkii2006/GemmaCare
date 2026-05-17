import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/app_constants.dart';
import 'place_insight_dao.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE doctors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        specialty TEXT,
        hospital TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        rating REAL,
        reviewCount INTEGER,
        phone TEXT,
        appointmentProcess TEXT,
        peopleSay TEXT,
        consultationFee INTEGER,
        sources TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE hospitals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        rating REAL,
        phone TEXT,
        ambulanceNumber TEXT,
        hasAmbulance INTEGER DEFAULT 0,
        isOpen24Hours INTEGER DEFAULT 0,
        specialties TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE pharmacies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        latitude REAL,
        longitude REAL,
        phone TEXT,
        hours TEXT,
        isOpen INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctorName TEXT,
        specialty TEXT,
        hospital TEXT,
        dateTime TEXT,
        notes TEXT,
        isUpcoming INTEGER DEFAULT 1
      )
    ''');
    await PlaceInsightDao.createTable(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await PlaceInsightDao.createTable(db);
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE appointments ADD COLUMN prepChecklist TEXT DEFAULT ''");
      await db.execute("ALTER TABLE appointments ADD COLUMN questionsToAsk TEXT DEFAULT ''");
      await db.execute("ALTER TABLE appointments ADD COLUMN postNotes TEXT DEFAULT ''");
      await db.execute("ALTER TABLE appointments ADD COLUMN aiSummary TEXT DEFAULT ''");
    }
  }
}
