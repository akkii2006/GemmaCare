import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../../../providers/care_provider.dart';

class PlaceInsightDao {
  static const String table = 'place_insights';

  /// Call this in AppDatabase._onCreate and onUpgrade
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        place_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        lat REAL,
        lng REAL,
        rating REAL,
        user_ratings_total INTEGER,
        open_now INTEGER,
        place_types TEXT,
        distance_km REAL,
        specialization TEXT,
        pros TEXT,
        cons TEXT,
        recommended_for_user INTEGER,
        recommendation_reason TEXT,
        phone TEXT,
        website TEXT,
        weekday_hours TEXT,
        filtered_out INTEGER,
        filter_reason TEXT,
        analyzed_at TEXT,
        place_category TEXT
      )
    ''');
  }

  Future<HospitalInsight?> getInsight(String placeId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(table,
        where: 'place_id = ?', whereArgs: [placeId], limit: 1);
    if (rows.isEmpty) return null;
    return _rowToInsight(rows.first);
  }

  Future<List<HospitalInsight>> getInsightsByCategory(String category) async {
    final db = await AppDatabase.database;
    final rows = await db.query(table,
        where: 'place_category = ?', whereArgs: [category]);
    return rows.map(_rowToInsight).toList();
  }

  Future<void> saveInsight(HospitalInsight insight, {
    required String name,
    required String address,
    required double lat,
    required double lng,
    required double rating,
    required int userRatingsTotal,
    required double distanceKm,
    required List<String> placeTypes,
    required String category,
  }) async {
    final db = await AppDatabase.database;
    await db.insert(table, {
      'place_id': insight.placeId,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'open_now': insight.openNow ? 1 : 0,
      'place_types': jsonEncode(placeTypes),
      'distance_km': distanceKm,
      'specialization': insight.specialization,
      'pros': jsonEncode(insight.pros),
      'cons': jsonEncode(insight.cons),
      'recommended_for_user': insight.recommendedForUser ? 1 : 0,
      'recommendation_reason': insight.recommendationReason,
      'phone': insight.phone,
      'website': insight.website,
      'weekday_hours': jsonEncode(insight.weekdayHours),
      'filtered_out': insight.filteredOut ? 1 : 0,
      'filter_reason': insight.filterReason,
      'analyzed_at': DateTime.now().toIso8601String(),
      'place_category': category,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> hasInsight(String placeId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(table,
        columns: ['place_id'],
        where: 'place_id = ?',
        whereArgs: [placeId],
        limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> clear() async {
    final db = await AppDatabase.database;
    await db.delete(table);
  }

  HospitalInsight _rowToInsight(Map<String, dynamic> r) {
    return HospitalInsight(
      placeId: r['place_id'] as String,
      specialization: r['specialization'] as String? ?? 'general',
      pros: List<String>.from(jsonDecode(r['pros'] as String? ?? '[]')),
      cons: List<String>.from(jsonDecode(r['cons'] as String? ?? '[]')),
      recommendedForUser: (r['recommended_for_user'] as int? ?? 0) == 1,
      recommendationReason: r['recommendation_reason'] as String? ?? '',
      phone: r['phone'] as String? ?? '',
      website: r['website'] as String? ?? '',
      weekdayHours: List<String>.from(
          jsonDecode(r['weekday_hours'] as String? ?? '[]')),
      openNow: (r['open_now'] as int? ?? 0) == 1,
      filteredOut: (r['filtered_out'] as int? ?? 0) == 1,
      filterReason: r['filter_reason'] as String? ?? '',
    );
  }
}
