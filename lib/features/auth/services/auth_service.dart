import '../../../core/network/api_client.dart';
import '../../../core/storage/shared_prefs.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;
  final SharedPreferencesHelper _prefs;

  AuthService({ApiClient? apiClient, SharedPreferencesHelper? prefs})
    : _apiClient = apiClient ?? ApiClient(),
      _prefs = prefs ?? SharedPreferencesHelper();

  Future<void> initialize() async {
    await _apiClient.initialize();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  /// Validate username format
  bool _isValidUsername(String username) {
    return RegExp(r'^[a-z0-9_]+$').hasMatch(username);
  }

  Future<UserModel> login(String email, String password) async {
    if (!_isValidEmail(email)) {
      throw ValidationException('Invalid email format');
    }

    if (password.isEmpty) {
      throw ValidationException('Password is required');
    }

    try {
      print('Attempting login for email: $email');
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.login,
        body: {'email': email, 'password': password},
      );

      if (response['data'] == null) {
        throw ValidationException('Invalid response from server');
      }

      final user = UserModel.fromJson(response['data']);
      print('Login successful for user: ${user.username}');

      if (user.token == null) {
        throw ValidationException('No authentication token received');
      }

      print('Saving user data with token: ${user.token}');
      await _saveUserData(user);

      // Verify the saved token
      final savedToken = await _prefs.getToken();
      if (savedToken != user.token) {
        throw ValidationException('Token not saved correctly');
      }

      return user;
    } catch (e) {
      print('Login error: $e');
      await _prefs.clearAll(); // Clear any partial data
      rethrow;
    }
  }

  Future<UserModel> register(
    String username,
    String email,
    String password,
    String role,
  ) async {
    // Validate input
    if (!_isValidEmail(email)) {
      throw ValidationException('Invalid email format');
    }
    if (!_isValidUsername(username)) {
      throw ValidationException(
        'Username can only contain lowercase letters, numbers, and underscores',
      );
    }
    if (!['consumer', 'creator'].contains(role)) {
      throw ValidationException(
        'Invalid role. Must be either consumer or creator',
      );
    }
    if (password.isEmpty) {
      throw ValidationException('Password is required');
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.register,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      },
    );

    final user = UserModel.fromJson(response['data']);
    if (user.token != null) {
      await _saveUserData(user);
    }
    return user;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _prefs.getToken();
      print('Current token from storage: $token');

      if (token == null) {
        print('No token found in storage');
        return null;
      }

      // Ensure API client has the token
      _apiClient.setAuthToken(token);

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.currentUser,
      );

      if (response['data'] == null) {
        print('Invalid response from server for current user');
        await logout();
        return null;
      }

      final user = UserModel.fromJson(response['data']);
      print('Current user retrieved: ${user.username}');
      return user;
    } catch (e) {
      print('Error getting current user: $e');
      await logout(); // Clear invalid session
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _prefs.getToken();
    if (token == null) return false;

    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs.clearAll();
  }

  Future<void> _saveUserData(UserModel user) async {
    try {
      print('Starting to save user data');

      if (user.token == null) {
        throw ValidationException('Token is required for authentication');
      }

      // Save token first
      print('Saving token: ${user.token}');
      await _prefs.setToken(user.token!);
      _apiClient.setAuthToken(user.token!);

      // Save other user data
      print(
        'Saving user details - ID: ${user.id}, Role: ${user.role}, Username: ${user.username}',
      );
      await Future.wait([
        _prefs.setUserRole(user.role),
        _prefs.setUserId(user.id),
        _prefs.setUsername(user.username),
        if (user.profilePic.isNotEmpty) _prefs.setProfilePic(user.profilePic),
      ]);

      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
      await _prefs.clearAll(); // Clear any partial data
      rethrow;
    }
  }

  Future<String> updateProfilePicture(String imagePath) async {
    final formData =
        await _apiClient.createFormData({
              'image': await _apiClient.createMultipartFile(imagePath),
            })
            as Map<String, String>;

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.uploadProfilePicture,
      formData: formData,
    );

    return response['data']['profilePic'] as String;
  }
}
