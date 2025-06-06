import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _username;
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  bool get isInitialized => _isInitialized;

  AuthService() {
    // Constructor không gọi async method
    // Thay vào đó sẽ gọi từ main.dart
  }

  // Method này sẽ được gọi từ main.dart để đảm bảo đồng bộ
  Future<void> initializeAuth() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _username = prefs.getString('username');
      _isInitialized = true;

      if (kDebugMode) {
        print('AuthService initialized: isLoggedIn=$_isLoggedIn, username=$_username');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AuthService: $e');
      }
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> login(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);

      _isLoggedIn = true;
      _username = username;

      if (kDebugMode) {
        print('User logged in: $_username');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error during login: $e');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('username');

      _isLoggedIn = false;
      _username = null;

      if (kDebugMode) {
        print('User logged out');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
      rethrow;
    }
  }

  // Method để reload trạng thái auth (nếu cần)
  Future<void> refreshAuthState() async {
    await initializeAuth();
  }
}