import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../data/models/hospital_model.dart';
import '../../data/models/pharmacy_model.dart';

class PlacesService {
  Future<List<Hospital>> fetchNearbyHospitals(double lat, double lng) async {
    final url = Uri.parse(
      '${AppConstants.placesApiUrl}/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=${AppConstants.searchRadiusMeters}'
      '&type=hospital'
      '&key=${AppConstants.googleMapsApiKey}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final results = data['results'] as List<dynamic>;

    return results.map((r) {
      final location = r['geometry']['location'];
      return Hospital(
        name: r['name'] ?? '',
        type: 'Hospital',
        address: r['vicinity'] ?? '',
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
        rating: (r['rating'] ?? 0.0).toDouble(),
        phone: '',
        ambulanceNumber: '',
        hasAmbulance: true,
        isOpen24Hours: false,
        specialties: [],
      );
    }).toList();
  }

  Future<List<Pharmacy>> fetchNearbyPharmacies(double lat, double lng) async {
    final url = Uri.parse(
      '${AppConstants.placesApiUrl}/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=${AppConstants.searchRadiusMeters}'
      '&type=pharmacy'
      '&key=${AppConstants.googleMapsApiKey}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final results = data['results'] as List<dynamic>;

    return results.map((r) {
      final location = r['geometry']['location'];
      final openNow = r['opening_hours']?['open_now'] ?? false;
      return Pharmacy(
        name: r['name'] ?? '',
        address: r['vicinity'] ?? '',
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
        phone: '',
        hours: openNow ? 'Open now' : 'Closed',
        isOpen: openNow as bool,
      );
    }).toList();
  }
}
