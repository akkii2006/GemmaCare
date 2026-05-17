import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_profile_model.dart';
import '../data/local/preferences/app_preferences.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile.empty();
  bool _onboardingDone = false;

  UserProfile get profile => _profile;
  bool get onboardingDone => _onboardingDone;

  Future<void> init() async {
    final prefs = await AppPreferences.getInstance();
    _onboardingDone = prefs.isOnboardingDone;

    if (_onboardingDone) {
      _profile = UserProfile(
        name: prefs.userName,
        age: prefs.userAge,
        gender: prefs.userGender,
        bloodGroup: prefs.userBloodGroup,
        allergies: prefs.userAllergies,
        conditions: prefs.userConditions,
        privacyMode: prefs.isPrivacyMode,
        latitude: prefs.userLatitude,
        longitude: prefs.userLongitude,
      );
    }

    notifyListeners();
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    _profile = profile;
    _onboardingDone = true;

    final prefs = await AppPreferences.getInstance();
    await prefs.setOnboardingDone(true);
    await prefs.setUserName(profile.name);
    await prefs.setUserAge(profile.age);
    await prefs.setUserGender(profile.gender);
    await prefs.setUserBloodGroup(profile.bloodGroup);
    await prefs.setUserAllergies(profile.allergies);
    await prefs.setUserConditions(profile.conditions);
    await prefs.setPrivacyMode(profile.privacyMode);
    await prefs.setUserLatitude(profile.latitude);
    await prefs.setUserLongitude(profile.longitude);

    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;

    final prefs = await AppPreferences.getInstance();
    await prefs.setUserName(profile.name);
    await prefs.setUserAge(profile.age);
    await prefs.setUserGender(profile.gender);
    await prefs.setUserBloodGroup(profile.bloodGroup);
    await prefs.setUserAllergies(profile.allergies);
    await prefs.setUserConditions(profile.conditions);
    await prefs.setPrivacyMode(profile.privacyMode);
    await prefs.setUserLatitude(profile.latitude);
    await prefs.setUserLongitude(profile.longitude);

    notifyListeners();
  }

  /// Wipes all SharedPreferences and resets state.
  /// After calling this, restart the app or navigate to onboarding.
  Future<void> deleteAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _profile = UserProfile.empty();
    _onboardingDone = false;
    notifyListeners();
  }
}