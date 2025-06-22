import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  String? _token;
  final ApiService _apiService = ApiService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await _apiService.login(email: email, password: password);
    if (result['success']) {
      _user = result['user'];
      _isLoggedIn = true;
    } else {
      _error = result['message'];
      _isLoggedIn = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(
      String name, String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await _apiService.register(
        name: name, email: email, password: password, role: role);
    if (result['success']) {
      _user = result['user'];
      _isLoggedIn = true;
    } else {
      _error = result['message'];
      _isLoggedIn = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _apiService.logout();
    _user = null;
    _isLoggedIn = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();
    final result = await _apiService.getUserProfile();
    if (result['success']) {
      _user = result['user'];
      _isLoggedIn = true;
    } else {
      _error = result['message'];
      _isLoggedIn = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(SharedPrefsKeys.token)) {
      return false;
    }

    try {
      final storedToken = prefs.getString(SharedPrefsKeys.token);
      final storedUserData = prefs.getString(SharedPrefsKeys.userData);

      if (storedToken == null || storedUserData == null) {
        logout(); // Clean up partial data
        return false;
      }

      _token = storedToken;
      _user = User.fromJson(json.decode(storedUserData));
      notifyListeners();
      return true;
    } catch (error) {
      // If any error occurs during auto-login (e.g., parsing user data),
      // treat it as a failed login and clear all stored data.
      logout();
      return false;
    }
  }

  Future<Map<String, dynamic>> updateAccount(
      {required String name, required String email}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.updateAccount(name: name, email: email);

      if (result['success']) {
        // Refresh user profile data after successful update
        await loadUserProfile();
        // If loadUserProfile fails, it will set its own error message.
        // The result from updateAccount should still be returned.
        return result;
      } else {
        // The update call itself failed
        _error = result['message'] ?? 'Failed to update profile.';
        return result;
      }
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
