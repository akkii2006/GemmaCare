class Pharmacy {
  final int? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String hours;
  final bool isOpen;

  const Pharmacy({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.hours,
    required this.isOpen,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'hours': hours,
        'isOpen': isOpen ? 1 : 0,
      };

  factory Pharmacy.fromMap(Map<String, dynamic> map) => Pharmacy(
        id: map['id'],
        name: map['name'] ?? '',
        address: map['address'] ?? '',
        latitude: map['latitude'] ?? 0.0,
        longitude: map['longitude'] ?? 0.0,
        phone: map['phone'] ?? '',
        hours: map['hours'] ?? '',
        isOpen: (map['isOpen'] ?? 0) == 1,
      );
}
