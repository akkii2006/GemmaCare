import 'package:flutter/material.dart';
import '../data/local/preferences/app_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _privacyMode = false;
  bool _darkMode = false;

  bool get privacyMode => _privacyMode;
  bool get darkMode => _darkMode;

  Future<void> init() async {
    final prefs = await AppPreferences.getInstance();
    _privacyMode = prefs.isPrivacyMode;
    _darkMode = prefs.isDarkMode;
    notifyListeners();
  }

  Future<void> setPrivacyMode(bool value) async {
    _privacyMode = value;
    final prefs = await AppPreferences.getInstance();
    await prefs.setPrivacyMode(value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await AppPreferences.getInstance();
    await prefs.setDarkMode(value);
    notifyListeners();
  }
}
