import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';

class SharedPreferencesHelper {
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageConstants.TOKEN_KEY);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageConstants.TOKEN_KEY, token);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageConstants.USER_ROLE_KEY);
  }

  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageConstants.USER_ROLE_KEY, role);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageConstants.USER_ID_KEY);
  }

  Future<void> setUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageConstants.USER_ID_KEY, id);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageConstants.USERNAME_KEY);
  }

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageConstants.USERNAME_KEY, username);
  }

  Future<String?> getProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageConstants.PROFILE_PIC_KEY);
  }

  Future<void> setProfilePic(String profilePic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageConstants.PROFILE_PIC_KEY, profilePic);
  }

  Future<Map<String, String?>> getAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(StorageConstants.TOKEN_KEY),
      'userId': prefs.getString(StorageConstants.USER_ID_KEY),
      'username': prefs.getString(StorageConstants.USERNAME_KEY),
      'role': prefs.getString(StorageConstants.USER_ROLE_KEY),
      'profilePic': prefs.getString(StorageConstants.PROFILE_PIC_KEY),
    };
  }

  Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageConstants.TOKEN_KEY);
    final userId = prefs.getString(StorageConstants.USER_ID_KEY);
    final role = prefs.getString(StorageConstants.USER_ROLE_KEY);
    return token != null && userId != null && role != null;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
