import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../data/models/hospital_model.dart';
import '../../data/models/pharmacy_model.dart';

class OverpassService {
  Future<List<Hospital>> fetchNearbyHospitals(double lat, double lng) async {
    final radius = AppConstants.searchRadiusMeters;
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:$radius,$lat,$lng);
  way["amenity"="hospital"](around:$radius,$lat,$lng);
  node["amenity"="clinic"](around:$radius,$lat,$lng);
  way["amenity"="clinic"](around:$radius,$lat,$lng);
);
out center;
''';

    final response = await http.post(
      Uri.parse(AppConstants.overpassApiUrl),
      body: {'data': query},
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final elements = data['elements'] as List<dynamic>;

    return elements.map((e) {
      final tags = e['tags'] as Map<String, dynamic>? ?? {};
      final double eLat = (e['lat'] ?? e['center']?['lat'] ?? 0).toDouble();
      final double eLng = (e['lon'] ?? e['center']?['lon'] ?? 0).toDouble();

      return Hospital(
        name: tags['name'] ?? 'Unknown Hospital',
        type: tags['amenity'] == 'clinic' ? 'Clinic' : 'Hospital',
        address: _buildAddress(tags),
        latitude: eLat,
        longitude: eLng,
        rating: 0.0,
        phone: tags['phone'] ?? tags['contact:phone'] ?? '',
        ambulanceNumber: tags['phone'] ?? '',
        hasAmbulance: tags['amenity'] == 'hospital',
        isOpen24Hours: tags['opening_hours'] == '24/7',
        specialties: [],
      );
    }).where((h) => h.name != 'Unknown Hospital').toList();
  }

  Future<List<Pharmacy>> fetchNearbyPharmacies(double lat, double lng) async {
    final radius = AppConstants.searchRadiusMeters;
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="pharmacy"](around:$radius,$lat,$lng);
  way["amenity"="pharmacy"](around:$radius,$lat,$lng);
);
out center;
''';

    final response = await http.post(
      Uri.parse(AppConstants.overpassApiUrl),
      body: {'data': query},
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final elements = data['elements'] as List<dynamic>;

    return elements.map((e) {
      final tags = e['tags'] as Map<String, dynamic>? ?? {};
      final double eLat = (e['lat'] ?? e['center']?['lat'] ?? 0).toDouble();
      final double eLng = (e['lon'] ?? e['center']?['lon'] ?? 0).toDouble();

      return Pharmacy(
        name: tags['name'] ?? 'Unknown Pharmacy',
        address: _buildAddress(tags),
        latitude: eLat,
        longitude: eLng,
        phone: tags['phone'] ?? tags['contact:phone'] ?? '',
        hours: tags['opening_hours'] ?? 'Hours not available',
        isOpen: false,
      );
    }).where((p) => p.name != 'Unknown Pharmacy').toList();
  }

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    if (tags['addr:street'] != null) parts.add(tags['addr:street']);
    if (tags['addr:city'] != null) parts.add(tags['addr:city']);
    return parts.join(', ');
  }
}
