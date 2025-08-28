import 'dart:io';
import 'package:flutter/foundation.dart';
import '../features/auth/models/user_model.dart';
import '../features/auth/services/auth_service.dart';
import '../core/errors/exceptions.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();
    await _checkAuthStatus();
  }

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final currentUser = await _authService.getCurrentUser();
        if (currentUser != null) {
          _user = currentUser;
          _status = AuthStatus.authenticated;

          // Additional validation for role-based access
          if (_user!.role != 'creator' && _user!.role != 'consumer') {
            _status = AuthStatus.error;
            _error = 'Invalid user role';
            await _authService.logout();
          }
        } else {
          _status = AuthStatus.unauthenticated;
          await _authService.logout();
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      await _authService.logout();
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      _user = await _authService.login(email, password);
      if (_user == null) {
        _status = AuthStatus.error;
        _error = 'Login failed';
      } else if (_user!.role != 'creator' && _user!.role != 'consumer') {
        _status = AuthStatus.error;
        _error = 'Invalid user role';
        await _authService.logout();
        _user = null;
      } else {
        _status = AuthStatus.authenticated;
      }
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _error = e.message;
      await _authService.logout();
      _user = null;
    } catch (e) {
      _status = AuthStatus.error;
      _error = 'An unexpected error occurred';
      await _authService.logout();
      _user = null;
    }
    notifyListeners();
  }

  Future<void> register(
    String username,
    String email,
    String password,
    String role,
  ) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      if (role != 'creator' && role != 'consumer') {
        _status = AuthStatus.error;
        _error = 'Invalid role selected';
        notifyListeners();
        return;
      }

      _user = await _authService.register(username, email, password, role);
      if (_user == null) {
        _status = AuthStatus.error;
        _error = 'Registration failed';
      } else {
        _status = AuthStatus.authenticated;
      }
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _error = e.message;
    } catch (e) {
      _status = AuthStatus.error;
      _error = 'An unexpected error occurred';
    }
    notifyListeners();
  }

  Future<void> updateProfilePicture(File image) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final newProfilePicUrl = await _authService.updateProfilePicture(
        image.path,
      );
      _user = _user?.copyWith(profilePic: newProfilePicUrl);
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to update profile picture';
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = 'Failed to logout';
    }
    notifyListeners();
  }
}
