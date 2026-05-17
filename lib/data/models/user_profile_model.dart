class UserProfile {
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> conditions;
  final bool privacyMode;
  final double? latitude;
  final double? longitude;

  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.allergies,
    required this.conditions,
    required this.privacyMode,
    this.latitude,
    this.longitude,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? conditions,
    bool? privacyMode,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      privacyMode: privacyMode ?? this.privacyMode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'age': age,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'allergies': allergies.join(','),
        'conditions': conditions.join(','),
        'privacyMode': privacyMode ? 1 : 0,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        name: map['name'] ?? '',
        age: map['age'] ?? 0,
        gender: map['gender'] ?? '',
        bloodGroup: map['bloodGroup'] ?? '',
        allergies: (map['allergies'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
        conditions: (map['conditions'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
        privacyMode: (map['privacyMode'] ?? 0) == 1,
        latitude: map['latitude'],
        longitude: map['longitude'],
      );

  factory UserProfile.empty() => const UserProfile(
        name: '',
        age: 0,
        gender: '',
        bloodGroup: '',
        allergies: [],
        conditions: [],
        privacyMode: false,
      );
}
