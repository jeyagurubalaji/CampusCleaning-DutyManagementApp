import 'package:flutter/material.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  String get role => _user?.role ?? '';

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        final data = await ApiService.getMe();
        final userData = data['data'] ?? data['user'] ?? data;
        _user = User.fromJson(userData);
      }
    } catch (e) {
      await ApiService.clearToken();
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.login(email, password);
      final userData = data['data'] ?? data['user'] ?? data;
      _user = User.fromJson(userData);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }
}