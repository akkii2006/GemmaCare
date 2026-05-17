import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/places/google_places_service.dart';
import '../services/ai/gemma_remote_service.dart';
import '../services/search/serper_service.dart';
import '../core/constants/app_constants.dart';
import '../data/local/database/place_insight_dao.dart';

class HospitalInsight {
  final String placeId;
  final String specialization;
  final List<String> pros;
  final List<String> cons;
  final bool recommendedForUser;
  final String recommendationReason;
  final String phone;
  final String website;
  final List<String> weekdayHours;
  final bool openNow;
  final bool filteredOut;
  final String filterReason;
  final double? webRating;

  const HospitalInsight({
    required this.placeId,
    required this.specialization,
    required this.pros,
    required this.cons,
    required this.recommendedForUser,
    required this.recommendationReason,
    required this.phone,
    required this.website,
    required this.weekdayHours,
    required this.openNow,
    this.filteredOut = false,
    this.filterReason = '',
    this.webRating,
  });

  Map<String, dynamic> toJson() => {
    'placeId': placeId,
    'specialization': specialization,
    'pros': pros,
    'cons': cons,
    'recommendedForUser': recommendedForUser,
    'recommendationReason': recommendationReason,
    'phone': phone,
    'website': website,
    'weekdayHours': weekdayHours,
    'openNow': openNow,
    'filteredOut': filteredOut,
    'filterReason': filterReason,
    'webRating': webRating,
  };

  factory HospitalInsight.fromJson(Map<String, dynamic> j) => HospitalInsight(
    placeId: j['placeId'] ?? '',
    specialization: j['specialization'] ?? 'general',
    pros: List<String>.from(j['pros'] ?? []),
    cons: List<String>.from(j['cons'] ?? []),
    recommendedForUser: j['recommendedForUser'] ?? false,
    recommendationReason: j['recommendationReason'] ?? '',
    phone: j['phone'] ?? '',
    website: j['website'] ?? '',
    weekdayHours: List<String>.from(j['weekdayHours'] ?? []),
    openNow: j['openNow'] ?? false,
    filteredOut: j['filteredOut'] ?? false,
    filterReason: j['filterReason'] ?? '',
    webRating: (j['webRating'] as num?)?.toDouble(),
  );
}

class CareProvider extends ChangeNotifier {
  final GooglePlacesService _places = GooglePlacesService();
  final GemmaRemoteService _remote = GemmaRemoteService();
  final SerperService _serper = SerperService();
  final PlaceInsightDao _dao = PlaceInsightDao();

  static const String _insightsCacheKey = 'care_insights_cache_v2';
  static const String _radiusKey = 'care_radius_meters';

  List<PlaceResult> _hospitals = [];
  List<PlaceResult> _doctors = [];
  List<PlaceResult> _pharmacies = [];

  final Map<String, HospitalInsight> _insights = {};
  final Map<String, PlaceDetails> _detailsCache = {};

  bool _isLoading = false;
  bool _isLoadingInsights = false;
  String? _error;
  String _insightProgress = '';
  int _radiusMeters = AppConstants.searchRadiusMeters;

  // Smart search
  List<PlaceResult> _searchResults = [];
  bool _isSearching = false;

  List<PlaceResult> get hospitals => _hospitals;
  List<PlaceResult> get doctors => _doctors;
  List<PlaceResult> get pharmacies => _pharmacies;
  Map<String, HospitalInsight> get insights => Map.unmodifiable(_insights);
  bool get isLoading => _isLoading;
  bool get isLoadingInsights => _isLoadingInsights;
  String? get error => _error;
  String get insightProgress => _insightProgress;
  int get radiusMeters => _radiusMeters;
  List<PlaceResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _radiusMeters = prefs.getInt(_radiusKey) ?? AppConstants.searchRadiusMeters;
    await _loadInsightsCache();
  }

  Future<void> setRadius(int meters) async {
    _radiusMeters = meters;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_radiusKey, meters);
    _hospitals = [];
    _doctors = [];
    _pharmacies = [];
    notifyListeners();
  }

  Future<void> _loadInsightsCache() async {
    // Load from SQLite DB (permanent cache)
    try {
      final allInsights = await _dao.getInsightsByCategory('hospital');
      for (final insight in allInsights) {
        _insights[insight.placeId] = insight;
      }
      final doctorInsights = await _dao.getInsightsByCategory('doctor');
      for (final insight in doctorInsights) {
        _insights[insight.placeId] = insight;
      }
      final pharmacyInsights = await _dao.getInsightsByCategory('pharmacy');
      for (final insight in pharmacyInsights) {
        _insights[insight.placeId] = insight;
      }
      if (_insights.isNotEmpty) notifyListeners();
    } catch (e) {
      print('[CARE] DB load error: \$e');
    }
    // Also load SharedPreferences cache as fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_insightsCacheKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          if (!_insights.containsKey(k)) {
            _insights[k] = HospitalInsight.fromJson(v as Map<String, dynamic>);
          }
        });
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveInsightsCache() async {
    // SharedPreferences backup
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _insights.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_insightsCacheKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _saveInsightToDb(HospitalInsight insight, PlaceResult place, String category) async {
    try {
      await _dao.saveInsight(
        insight,
        name: place.name,
        address: place.address,
        lat: place.lat,
        lng: place.lng,
        rating: place.rating,
        userRatingsTotal: place.userRatingsTotal,
        distanceKm: place.distanceKm,
        placeTypes: place.types,
        category: category,
      );
      print('[CARE] Saved to DB: \${place.name}');
    } catch (e) {
      print('[CARE] DB save error: \$e');
    }
  }

  Future<void> fetchNearby({
    required double lat,
    required double lng,
    List<String> userConditions = const [],
    String? userGender,
    int? userAge,
    bool forceRefresh = false,
  }) async {
    print('[CARE] fetchNearby called: lat=$lat lng=$lng radius=$_radiusMeters forceRefresh=$forceRefresh hospitals=${_hospitals.length} isLoading=$_isLoading');
    if (!forceRefresh && (_isLoading || _hospitals.isNotEmpty)) {
      print('[CARE] fetchNearby SKIPPED');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[CARE] Calling Places API...');
      final results = await Future.wait([
        _places.searchNearby(lat: lat, lng: lng, type: 'hospital', radius: _radiusMeters),
        _places.searchNearby(lat: lat, lng: lng, type: 'doctor', radius: _radiusMeters),
        _places.searchNearby(lat: lat, lng: lng, type: 'pharmacy', radius: _radiusMeters),
      ]);

      print('[CARE] Results: hospitals=${results[0].length} doctors=${results[1].length} pharmacies=${results[2].length}');
      _hospitals = results[0];
      // Filter doctors to exclude hospitals/medical centers
      _doctors = results[1].where((p) =>
        !p.types.any((t) => t == 'hospital') &&
        !p.name.toLowerCase().contains('hospital') &&
        !p.name.toLowerCase().contains('medical center') &&
        !p.name.toLowerCase().contains('healthcare')
      ).toList();
      _pharmacies = results[2];
      _isLoading = false;
      notifyListeners();

      if (_hospitals.isNotEmpty) {
        _fetchInsights(
          places: _hospitals.take(10).toList(),
          userConditions: userConditions,
          userGender: userGender,
          userAge: userAge,
          type: 'hospital',
        );
      }
    } catch (e) {
      print('[CARE] fetchNearby ERROR: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _fetchInsights({
    required List<PlaceResult> places,
    required List<String> userConditions,
    String? userGender,
    int? userAge,
    required String type,
  }) async {
    _isLoadingInsights = true;
    notifyListeners();

    for (int i = 0; i < places.length; i++) {
      final place = places[i];
      if (_insights.containsKey(place.placeId)) continue;

      _insightProgress = 'Analyzing ${place.name} (${i + 1}/${places.length})...';
      notifyListeners();

      try {
        final details = await _places.getDetails(place.placeId);
        if (details == null) continue;
        _detailsCache[place.placeId] = details;

        // Fetch web reviews from Serper in parallel
        final city = _extractCity(place.address);
        final webReviewsFuture = _serper.getWebReviews(place.name, city);

        String reviewsText = '';
        if (details.reviews.isNotEmpty) {
          reviewsText = details.reviews
              .asMap()
              .entries
              .map((e) => '[G${e.key + 1}] ${e.value.author} (${e.value.rating}★): ${e.value.text}')
              .join('\n\n');
        }

        final webReviews = await webReviewsFuture;
        if (webReviews.isNotEmpty) {
          reviewsText += reviewsText.isNotEmpty
              ? '\n\nWeb reviews:\n$webReviews'
              : 'Web reviews:\n$webReviews';
        }

        if (reviewsText.isEmpty) {
          _insights[place.placeId] = HospitalInsight(
            placeId: place.placeId,
            specialization: 'general',
            pros: [],
            cons: [],
            recommendedForUser: false,
            recommendationReason: 'No reviews available',
            phone: details.phone,
            website: details.website,
            weekdayHours: details.weekdayHours,
            openNow: details.openNow,
          );
          await _saveInsightsCache();
          notifyListeners();
          continue;
        }

        final conditionsText = userConditions.isNotEmpty
            ? userConditions.join(', ')
            : 'none';

        final profileText = [
          if (userGender != null && userGender.isNotEmpty) 'Gender: $userGender',
          if (userAge != null && userAge > 0) 'Age: $userAge',
          'Medical conditions: $conditionsText',
        ].join(', ');

        final typeLabel = type == 'hospital' ? 'hospital' : type == 'doctor' ? 'doctor/clinic' : 'pharmacy';

        final prompt = '''
Analyze this $typeLabel: "${place.name}"

User profile: $profileText

${type == 'hospital' ? '''Determine if appropriate for this user:
- Maternity/women's hospitals: NOT for male users
- Pediatric/children's hospitals: NOT for adults 18+
- All others: generally appropriate''' : ''}

Reviews (G=Google, Web=internet forums/Reddit):
$reviewsText

Respond ONLY with valid JSON:
{
  "filtered_out": false,
  "filter_reason": "",
  "specialization": "${type == 'hospital' ? 'cardiac/oncology/orthopedic/neurology/diabetes/maternity/pediatric/general' : type == 'doctor' ? 'cardiologist/neurologist/orthopedic/general physician/dermatologist/gynecologist/pediatrician/psychiatrist/other' : 'general/specialty/24hr'}",
  "pros": ["point from reviews"],
  "cons": ["point from reviews"],
  "recommended_for_user": true,
  "recommendation_reason": "one sentence based on user profile"
}''';

        print('[CARE] Analyzing $type ${i + 1}/${places.length}: ${place.name}');

        final response = await _remote.chat(
          systemPrompt: 'Medical facility analyst. JSON only, no markdown.',
          messages: [{'role': 'user', 'content': prompt}],
          model: AppConstants.careModelId,
        ).timeout(const Duration(seconds: 60), onTimeout: () {
          throw Exception('Timeout');
        });

        print('[CARE] Done: ${place.name} (${response.length} chars)');

        final clean = response.replaceAll('```json', '').replaceAll('```', '').trim();
        final json = jsonDecode(clean);

        _insights[place.placeId] = HospitalInsight(
          placeId: place.placeId,
          specialization: json['specialization'] ?? 'general',
          pros: List<String>.from(json['pros'] ?? []),
          cons: List<String>.from(json['cons'] ?? []),
          recommendedForUser: json['recommended_for_user'] ?? false,
          recommendationReason: json['recommendation_reason'] ?? '',
          phone: details.phone,
          website: details.website,
          weekdayHours: details.weekdayHours,
          openNow: details.openNow,
          filteredOut: json['filtered_out'] ?? false,
          filterReason: json['filter_reason'] ?? '',
        );

        await _saveInsightsCache();
        _resortHospitals();
      } catch (e) {
        print('[CARE] ERROR ${place.name}: $e');
      }
    }

    _isLoadingInsights = false;
    _insightProgress = '';
    notifyListeners();
  }

  String _extractCity(String address) {
    final parts = address.split(',');
    return parts.length >= 2 ? parts[parts.length - 2].trim() : address;
  }

  void _resortHospitals() {
    _hospitals.sort((a, b) {
      final iA = _insights[a.placeId];
      final iB = _insights[b.placeId];
      final filtA = iA?.filteredOut ?? false;
      final filtB = iB?.filteredOut ?? false;
      if (filtA && !filtB) return 1;
      if (!filtA && filtB) return -1;
      final recA = iA?.recommendedForUser ?? false;
      final recB = iB?.recommendedForUser ?? false;
      if (recA && !recB) return -1;
      if (!recA && recB) return 1;
      return a.distanceKm.compareTo(b.distanceKm);
    });
    notifyListeners();
  }

  /// Smart search: natural language query → find nearby places
  Future<void> smartSearch({
    required String query,
    required double lat,
    required double lng,
    List<String> userConditions = const [],
    String? userGender,
    int? userAge,
  }) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      // Ask Gemini to interpret the query
      final interpretation = await _remote.chat(
        systemPrompt: 'You are a medical search assistant. Respond only with JSON.',
        messages: [{
          'role': 'user',
          'content': '''User searched: "$query"
Determine the best Google Places search type and keyword.
Respond with JSON only:
{
  "type": "hospital OR doctor OR pharmacy",
  "keyword": "specific specialty or name to search for"
}
Examples:
- "cardiologist near me" → {"type":"doctor","keyword":"cardiologist"}
- "Apollo hospital" → {"type":"hospital","keyword":"Apollo"}
- "24 hour pharmacy" → {"type":"pharmacy","keyword":"24 hour pharmacy"}
- "diabetes specialist" → {"type":"doctor","keyword":"diabetologist endocrinologist"}'''
        }],
        model: AppConstants.careModelId,
      ).timeout(const Duration(seconds: 15));

      final clean = interpretation.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(clean);
      final type = parsed['type'] ?? 'hospital';
      final keyword = parsed['keyword'] ?? query;

      final results = await _places.searchNearby(
        lat: lat,
        lng: lng,
        type: type,
        keyword: keyword,
        radius: _radiusMeters,
      );

      _searchResults = results;
      _isSearching = false;
      notifyListeners();

      // Fetch insights for search results
      if (results.isNotEmpty) {
        _fetchInsights(
          places: results.take(5).toList(),
          userConditions: userConditions,
          userGender: userGender,
          userAge: userAge,
          type: type,
        );
      }
    } catch (e) {
      print('[CARE] Search error: $e');
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<PlaceDetails?> getDetails(String placeId) async {
    if (_detailsCache.containsKey(placeId)) return _detailsCache[placeId];
    final details = await _places.getDetails(placeId);
    if (details != null) _detailsCache[placeId] = details;
    return details;
  }

  Future<void> refresh({
    required double lat,
    required double lng,
    List<String> userConditions = const [],
    String? userGender,
    int? userAge,
  }) async {
    // Only clear in-memory lists and SharedPrefs — NEVER clear SQLite DB
    _hospitals = [];
    _doctors = [];
    _pharmacies = [];
    _insights.clear();
    // Reload DB insights so they're available immediately
    await _loadInsightsCache();
    notifyListeners();
    await fetchNearby(
      lat: lat,
      lng: lng,
      userConditions: userConditions,
      userGender: userGender,
      userAge: userAge,
      forceRefresh: true,
    );
  }

  void clear() {
    _hospitals = [];
    _doctors = [];
    _pharmacies = [];
    _insights.clear();
    _detailsCache.clear();
    _error = null;
    notifyListeners();
  }
}
