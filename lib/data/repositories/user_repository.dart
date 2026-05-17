import '../local/preferences/app_preferences.dart';
import '../models/user_profile_model.dart';

class UserRepository {
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await AppPreferences.getInstance();
    await prefs.setUserName(profile.name);
    await prefs.setPrivacyMode(profile.privacyMode);
  }
}
