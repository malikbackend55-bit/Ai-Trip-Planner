import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    // Optionally fetch user profile if token exists
    if (_token != null) {
      notifyListeners();
      try {
        final response = await _apiService.getUser();
        _user = response.data;
        notifyListeners();
      } catch (e) {
        logout();
      }
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.login(email, password);
      _token = response.data['token'];
      _user = response.data['user'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      
      _isLoading = false;
      notifyListeners();
      return null; // Return null on success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e) ?? 'Login failed. Please check your credentials.';
    }
  }

  Future<String?> register(String name, String email, String phone, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.register(name, email, phone, password);
      _token = response.data['token'];
      _user = response.data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

      _isLoading = false;
      notifyListeners();
      return null; // Return null on success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e) ?? 'Registration failed. Please try again.';
    }
  }

  Future<String?> forgotPassword(String email, String phone, String password, String passwordConfirmation) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.forgotPassword(email, phone, password, passwordConfirmation);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e) ?? 'Password reset failed. Please try again.';
    }
  }

  String? _extractErrorMessage(dynamic error) {
    if (error is DioException && error.response != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('errors') && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
             final firstError = errors.values.first;
             if (firstError is List && firstError.isNotEmpty) {
               return firstError.first.toString();
             }
             return firstError.toString();
          }
        }
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
      }

      final statusCode = error.response!.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return 'Server error ($statusCode). Check backend logs.';
      }
    }

    if (error is DioException && error.response == null) {
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Cannot reach server at ${ApiService.baseUrl}. Check API_URL and backend status.';
        default:
          final message = error.message?.trim();
          if (message != null && message.isNotEmpty) {
            return message;
          }
      }
    }

    return null;
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {
      // Ignore API errors — always clear local state
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _user = null;
    notifyListeners();
  }
}

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) => AuthProvider());
