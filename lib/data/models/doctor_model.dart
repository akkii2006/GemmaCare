class Doctor {
  final int? id;
  final String name;
  final String specialty;
  final String hospital;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phone;
  final String appointmentProcess;
  final String peopleSay;
  final int consultationFee;
  final List<String> sources;

  const Doctor({
    this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phone,
    required this.appointmentProcess,
    required this.peopleSay,
    required this.consultationFee,
    required this.sources,
  });

  double distanceFrom(double lat, double lng) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        ((lat - latitude) * p / 2 * ((lat - latitude) * p / 2)) +
        ((latitude * p).hashCode * (lat * p).hashCode) * ((lng - longitude) * p / 2 * ((lng - longitude) * p / 2));
    return 12742 * (a < 1 ? a : 1);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'hospital': hospital,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'reviewCount': reviewCount,
        'phone': phone,
        'appointmentProcess': appointmentProcess,
        'peopleSay': peopleSay,
        'consultationFee': consultationFee,
        'sources': sources.join(','),
      };

  factory Doctor.fromMap(Map<String, dynamic> map) => Doctor(
        id: map['id'],
        name: map['name'] ?? '',
        specialty: map['specialty'] ?? '',
        hospital: map['hospital'] ?? '',
        address: map['address'] ?? '',
        latitude: map['latitude'] ?? 0.0,
        longitude: map['longitude'] ?? 0.0,
        rating: map['rating'] ?? 0.0,
        reviewCount: map['reviewCount'] ?? 0,
        phone: map['phone'] ?? '',
        appointmentProcess: map['appointmentProcess'] ?? '',
        peopleSay: map['peopleSay'] ?? '',
        consultationFee: map['consultationFee'] ?? 0,
        sources: (map['sources'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      );
}
