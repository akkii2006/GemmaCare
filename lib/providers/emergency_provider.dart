import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/places/google_places_service.dart';
import '../services/search/serper_service.dart';
import '../core/constants/app_constants.dart';

class AmbulanceService {
  final String name;
  final String phone;
  final String address;
  final double? rating;
  final String source;
  final bool isPrivate;
  final bool isMajorHospital;

  const AmbulanceService({
    required this.name,
    required this.phone,
    required this.address,
    this.rating,
    required this.source,
    this.isPrivate = true,
    this.isMajorHospital = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'rating': rating,
    'source': source,
    'isPrivate': isPrivate,
    'isMajorHospital': isMajorHospital,
  };

  factory AmbulanceService.fromJson(Map<String, dynamic> j) =>
      AmbulanceService(
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        address: j['address'] ?? '',
        rating: (j['rating'] as num?)?.toDouble(),
        source: j['source'] ?? 'web',
        isPrivate: j['isPrivate'] ?? true,
        isMajorHospital: j['isMajorHospital'] ?? false,
      );
}

class EmergencyProvider extends ChangeNotifier {
  static const String _privateCacheKey = 'ambulance_private_v1';
  static const String _privateCityKey = 'ambulance_private_city';
  static const String _majorCacheKey = 'ambulance_major_v1';
  static const String _majorCityKey = 'ambulance_major_city';

  final GooglePlacesService _places = GooglePlacesService();
  final SerperService _serper = SerperService();
  static final http.Client _client = http.Client();

  List<AmbulanceService> _majorHospitalAmbulances = [];
  List<AmbulanceService> _privateAmbulances = [];

  bool _isLoadingMajor = false;
  bool _isLoadingPrivate = false;

  String? _error;

  List<AmbulanceService> get majorHospitalAmbulances =>
      _majorHospitalAmbulances;

  List<AmbulanceService> get privateAmbulances => _privateAmbulances;

  bool get isLoading => _isLoadingMajor || _isLoadingPrivate;

  bool get isLoadingMajor => _isLoadingMajor;

  bool get isLoadingPrivate => _isLoadingPrivate;

  String? get error => _error;

  String _loadedCity = '';

  Future<void> loadAmbulances({
    required double lat,
    required double lng,
    required String city,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _loadedCity == city &&
        _majorHospitalAmbulances.isNotEmpty) {
      print('[EMERGENCY] Already loaded for $city, skipping');
      return;
    }

    _loadedCity = city;

    await Future.wait([
      _loadMajorHospitalAmbulances(
        lat: lat,
        lng: lng,
        city: city,
        forceRefresh: forceRefresh,
      ),
      _loadPrivateAmbulances(
        lat: lat,
        lng: lng,
        city: city,
        forceRefresh: forceRefresh,
      ),
    ]);
  }

  Future<void> _loadMajorHospitalAmbulances({
    required double lat,
    required double lng,
    required String city,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached =
      await _loadCache(_majorCacheKey, _majorCityKey, city);

      if (cached.isNotEmpty) {
        _majorHospitalAmbulances = cached;
        notifyListeners();
        return;
      }
    }

    _isLoadingMajor = true;
    notifyListeners();

    try {
      final hospitalNames = await _getTopHospitalsFromGemma(city);

      print('[EMERGENCY] Top hospitals in $city: $hospitalNames');

      final results = <AmbulanceService>[];

      for (final name in hospitalNames.take(5)) {
        final phone =
        await _getHospitalAmbulanceNumber(name, city);

        results.add(
          AmbulanceService(
            name: name,
            phone: phone ?? '',
            address: city,
            source: 'web',
            isPrivate: false,
            isMajorHospital: true,
          ),
        );
      }

      _majorHospitalAmbulances = results;

      await _saveCache(
        results,
        _majorCacheKey,
        _majorCityKey,
        city,
      );
    } catch (e) {
      print('[EMERGENCY] Major hospital error: $e');
    }

    _isLoadingMajor = false;
    notifyListeners();
  }

  Future<List<String>> _getTopHospitalsFromGemma(
      String city,
      ) async {
    try {
      final response = await _client
          .post(
        Uri.parse(
          '${AppConstants.geminiBaseUrl}/gemma-4-31b-it:generateContent?key=${AppConstants.geminiApiKey}',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                  'List the 5 biggest and most well-known hospital names in $city. '
                      'Just the hospital names only, one per line, no numbers, '
                      'no bullet points, no descriptions, nothing else.'
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 150,
            'temperature': 0.1,
          },
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      final parts =
          (data['candidates']?[0]?['content']?['parts']
          as List?) ??
              [];

      String text = '';

      for (final part in parts) {
        if (part['thought'] != true) {
          text = (part['text'] ?? '') as String;
          break;
        }
      }

      return text
          .split('\n')
          .map(
            (l) => l
            .replaceAll(
          RegExp(r'^[\*\-\d\.\s]+'),
          '',
        )
            .trim(),
      )
          .where((l) => l.isNotEmpty && l.length > 3)
          .take(5)
          .toList();
    } catch (e) {
      print('[EMERGENCY] Gemma error: $e');
      return [];
    }
  }

  Future<String?> _getHospitalAmbulanceNumber(
      String hospitalName,
      String city,
      ) async {
    try {
      final results = await _serper.search(
        '$hospitalName $city ambulance number emergency helpline',
        num: 3,
      );

      for (final r in results) {
        final phones =
        _extractPhones(r.snippet + ' ' + r.title);

        if (phones.isNotEmpty) {
          return phones.first;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _loadPrivateAmbulances({
    required double lat,
    required double lng,
    required String city,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached =
      await _loadCache(_privateCacheKey, _privateCityKey, city);

      if (cached.isNotEmpty) {
        _privateAmbulances = cached;
        notifyListeners();
        return;
      }
    }

    _isLoadingPrivate = true;
    notifyListeners();

    try {
      final results = <AmbulanceService>[];

      final placesResults = await _places.searchNearby(
        lat: lat,
        lng: lng,
        type: 'hospital',
        keyword: 'ambulance service private',
        radius: 15000,
      );

      for (final p in placesResults.take(5)) {
        final details =
        await _places.getDetails(p.placeId);

        if (details != null &&
            details.phone.isNotEmpty) {
          results.add(
            AmbulanceService(
              name: p.name,
              phone: details.phone,
              address: p.address,
              rating: p.rating > 0 ? p.rating : null,
              source: 'places',
              isPrivate: true,
            ),
          );
        }
      }

      final serperResults = await _serper.search(
        'private ambulance service phone number $city 24 hour emergency',
        num: 6,
      );

      for (final r in serperResults) {
        final phones =
        _extractPhones(r.snippet + ' ' + r.title);

        for (final phone in phones) {
          if (!results.any((a) => a.phone == phone)) {
            results.add(
              AmbulanceService(
                name: r.title.length > 50
                    ? r.title.substring(0, 50)
                    : r.title,
                phone: phone,
                address: city,
                rating: r.rating,
                source: 'web',
                isPrivate: true,
              ),
            );
          }
        }
      }

      _privateAmbulances = results;

      await _saveCache(
        results,
        _privateCacheKey,
        _privateCityKey,
        city,
      );
    } catch (e) {
      print('[EMERGENCY] Private error: $e');
    }

    _isLoadingPrivate = false;
    notifyListeners();
  }

  List<String> _extractPhones(String text) {
    final results = <String>[];

    final patterns = [
      RegExp(r'\b(\+91[-\s]?)?[6-9]\d{9}\b'),
      RegExp(r'\b1\d{3}\b'),
      RegExp(r'\b\d{4,5}[-\s]\d{6,8}\b'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final phone = match.group(0)!
            .replaceAll(RegExp(r'[\s\-]'), '');

        if (phone.length >= 4 &&
            !results.contains(phone)) {
          results.add(phone);
        }
      }
    }

    return results.take(2).toList();
  }

  Future<List<AmbulanceService>> _loadCache(
      String key,
      String cityKey,
      String city,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getString(cityKey) != city) {
        return [];
      }

      final raw = prefs.getString(key);

      if (raw == null) {
        return [];
      }

      return (jsonDecode(raw) as List)
          .map((e) => AmbulanceService.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCache(
      List<AmbulanceService> services,
      String key,
      String cityKey,
      String city,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(cityKey, city);

      await prefs.setString(
        key,
        jsonEncode(
          services.map((s) => s.toJson()).toList(),
        ),
      );
    } catch (_) {}
  }
}