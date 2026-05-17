import '../data/repositories/care_repositories.dart';
import 'search/overpass_service.dart';
import 'search/places_service.dart';

class BackgroundSyncService {
  final OverpassService _overpass = OverpassService();
  final PlacesService _places = PlacesService();
  final HospitalRepository _hospitalRepo = HospitalRepository();
  final PharmacyRepository _pharmacyRepo = PharmacyRepository();

  Future<void> syncNearbyData(double lat, double lng) async {
    await Future.wait([
      _syncHospitals(lat, lng),
      _syncPharmacies(lat, lng),
    ]);
  }

  Future<void> _syncHospitals(double lat, double lng) async {
    try {
      var hospitals = await _overpass.fetchNearbyHospitals(lat, lng);

      // Fallback to Google Places if OSM returns few results
      if (hospitals.length < 3) {
        final placesHospitals = await _places.fetchNearbyHospitals(lat, lng);
        hospitals = [...hospitals, ...placesHospitals];
      }

      if (hospitals.isNotEmpty) {
        await _hospitalRepo.clear();
        await _hospitalRepo.insertAll(hospitals);
      }
    } catch (_) {}
  }

  Future<void> _syncPharmacies(double lat, double lng) async {
    try {
      var pharmacies = await _overpass.fetchNearbyPharmacies(lat, lng);

      if (pharmacies.length < 3) {
        final placesPharmacies = await _places.fetchNearbyPharmacies(lat, lng);
        pharmacies = [...pharmacies, ...placesPharmacies];
      }

      if (pharmacies.isNotEmpty) {
        await _pharmacyRepo.clear();
        await _pharmacyRepo.insertAll(pharmacies);
      }
    } catch (_) {}
  }
}
