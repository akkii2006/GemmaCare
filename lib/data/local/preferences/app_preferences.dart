import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyModelDownloaded = 'model_downloaded';
  static const String _keyPrivacyMode = 'privacy_mode';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyUserName = 'user_name';
  static const String _keyUserAge = 'user_age';
  static const String _keyUserGender = 'user_gender';
  static const String _keyUserBloodGroup = 'user_blood_group';
  static const String _keyUserAllergies = 'user_allergies';
  static const String _keyUserConditions = 'user_conditions';
  static const String _keyUserLatitude = 'user_latitude';
  static const String _keyUserLongitude = 'user_longitude';

  final SharedPreferences _prefs;
  AppPreferences(this._prefs);

  static Future<AppPreferences> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(prefs);
  }

  bool get isOnboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool value) => _prefs.setBool(_keyOnboardingDone, value);

  bool get isModelDownloaded => _prefs.getBool(_keyModelDownloaded) ?? false;
  Future<void> setModelDownloaded(bool value) => _prefs.setBool(_keyModelDownloaded, value);

  bool get isPrivacyMode => _prefs.getBool(_keyPrivacyMode) ?? false;
  Future<void> setPrivacyMode(bool value) => _prefs.setBool(_keyPrivacyMode, value);

  bool get isDarkMode => _prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_keyDarkMode, value);

  String get userName => _prefs.getString(_keyUserName) ?? '';
  Future<void> setUserName(String value) => _prefs.setString(_keyUserName, value);

  // Age stored as String to avoid int/long type mismatch on Android
  int get userAge {
    final raw = _prefs.get(_keyUserAge);
    if (raw == null) return 0;
    return int.tryParse(raw.toString()) ?? 0;
  }
  Future<void> setUserAge(int value) => _prefs.setString(_keyUserAge, value.toString());

  String get userGender => _prefs.getString(_keyUserGender) ?? '';
  Future<void> setUserGender(String value) => _prefs.setString(_keyUserGender, value);

  String get userBloodGroup => _prefs.getString(_keyUserBloodGroup) ?? '';
  Future<void> setUserBloodGroup(String value) => _prefs.setString(_keyUserBloodGroup, value);

  List<String> get userAllergies {
    final s = _prefs.getString(_keyUserAllergies) ?? '';
    return s.isEmpty ? [] : s.split(',').where((e) => e.isNotEmpty).toList();
  }
  Future<void> setUserAllergies(List<String> value) =>
      _prefs.setString(_keyUserAllergies, value.join(','));

  List<String> get userConditions {
    final s = _prefs.getString(_keyUserConditions) ?? '';
    return s.isEmpty ? [] : s.split(',').where((e) => e.isNotEmpty).toList();
  }
  Future<void> setUserConditions(List<String> value) =>
      _prefs.setString(_keyUserConditions, value.join(','));

  // Lat/lng stored as String to avoid double prefix encoding issue
  double? get userLatitude {
    final s = _prefs.getString(_keyUserLatitude);
    if (s == null) return null;
    return double.tryParse(s);
  }
  Future<void> setUserLatitude(double? value) {
    if (value == null) return _prefs.remove(_keyUserLatitude);
    return _prefs.setString(_keyUserLatitude, value.toString());
  }

  double? get userLongitude {
    final s = _prefs.getString(_keyUserLongitude);
    if (s == null) return null;
    return double.tryParse(s);
  }
  Future<void> setUserLongitude(double? value) {
    if (value == null) return _prefs.remove(_keyUserLongitude);
    return _prefs.setString(_keyUserLongitude, value.toString());
  }
}
