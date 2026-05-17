import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final int userRatingsTotal;
  final bool openNow;
  final List<String> types;
  final double distanceKm;

  const PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.userRatingsTotal,
    required this.openNow,
    required this.types,
    required this.distanceKm,
  });
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String phone;
  final String internationalPhone;
  final String website;
  final String address;
  final double rating;
  final List<PlaceReview> reviews;
  final List<String> weekdayHours;
  final bool openNow;
  final List<String> types;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.phone,
    required this.internationalPhone,
    required this.website,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.weekdayHours,
    required this.openNow,
    required this.types,
  });
}

class PlaceReview {
  final String author;
  final double rating;
  final String text;
  final String relativeTime;

  const PlaceReview({
    required this.author,
    required this.rating,
    required this.text,
    required this.relativeTime,
  });
}

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _key = AppConstants.googleMapsApiKey;

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<List<PlaceResult>> searchNearby({
    required double lat,
    required double lng,
    required String type,
    int radius = 10000,
    String? keyword,
  }) async {
    final kwParam = (keyword != null && keyword.isNotEmpty)
        ? ('&keyword=' + Uri.encodeComponent(keyword))
        : '';
    final url = _baseUrl + '/nearbysearch/json'
        + '?location=' + lat.toString() + ',' + lng.toString()
        + '&radius=' + radius.toString()
        + '&type=' + type
        + kwParam
        + '&key=' + _key;
    final uri = Uri.parse(url);

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') return [];

    final results = (data['results'] as List<dynamic>? ?? []);
    return results.map((r) {
      final loc = r['geometry']['location'];
      final placeLat = (loc['lat'] as num).toDouble();
      final placeLng = (loc['lng'] as num).toDouble();
      return PlaceResult(
        placeId: r['place_id'] ?? '',
        name: r['name'] ?? '',
        address: r['vicinity'] ?? '',
        lat: placeLat,
        lng: placeLng,
        rating: (r['rating'] as num?)?.toDouble() ?? 0.0,
        userRatingsTotal: (r['user_ratings_total'] as num?)?.toInt() ?? 0,
        openNow: r['opening_hours']?['open_now'] ?? false,
        types: List<String>.from(r['types'] ?? []),
        distanceKm: _haversine(lat, lng, placeLat, placeLng),
      );
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  Future<PlaceDetails?> getDetails(String placeId) async {
    final uri = Uri.parse(
      '$_baseUrl/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_phone_number,international_phone_number,'
          'opening_hours,website,rating,reviews,types,formatted_address'
          '&key=$_key',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') return null;

    final r = data['result'];
    final hours = r['opening_hours'];

    final reviews = (r['reviews'] as List<dynamic>? ?? [])
        .map((rv) => PlaceReview(
      author: rv['author_name'] ?? '',
      rating: (rv['rating'] as num?)?.toDouble() ?? 0.0,
      text: rv['text'] ?? '',
      relativeTime: rv['relative_time_description'] ?? '',
    ))
        .toList();

    return PlaceDetails(
      placeId: placeId,
      name: r['name'] ?? '',
      phone: r['formatted_phone_number'] ?? '',
      internationalPhone: r['international_phone_number'] ?? '',
      website: r['website'] ?? '',
      address: r['formatted_address'] ?? '',
      rating: (r['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: reviews,
      weekdayHours: List<String>.from(
          hours?['weekday_text'] ?? []),
      openNow: hours?['open_now'] ?? false,
      types: List<String>.from(r['types'] ?? []),
    );
  }
}