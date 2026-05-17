class Hospital {
  final int? id;
  final String name;
  final String type;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final String phone;
  final String ambulanceNumber;
  final bool hasAmbulance;
  final bool isOpen24Hours;
  final List<String> specialties;

  const Hospital({
    this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.phone,
    required this.ambulanceNumber,
    required this.hasAmbulance,
    required this.isOpen24Hours,
    required this.specialties,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'phone': phone,
        'ambulanceNumber': ambulanceNumber,
        'hasAmbulance': hasAmbulance ? 1 : 0,
        'isOpen24Hours': isOpen24Hours ? 1 : 0,
        'specialties': specialties.join(','),
      };

  factory Hospital.fromMap(Map<String, dynamic> map) => Hospital(
        id: map['id'],
        name: map['name'] ?? '',
        type: map['type'] ?? '',
        address: map['address'] ?? '',
        latitude: map['latitude'] ?? 0.0,
        longitude: map['longitude'] ?? 0.0,
        rating: (map['rating'] ?? 0.0).toDouble(),
        phone: map['phone'] ?? '',
        ambulanceNumber: map['ambulanceNumber'] ?? '',
        hasAmbulance: (map['hasAmbulance'] ?? 0) == 1,
        isOpen24Hours: (map['isOpen24Hours'] ?? 0) == 1,
        specialties: (map['specialties'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      );
}
