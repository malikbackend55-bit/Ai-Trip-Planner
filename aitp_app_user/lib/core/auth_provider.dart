import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'app_localization.dart';

class AuthProvider extends ChangeNotifier {
  static const String _authTokenKey = 'auth_token';
  static const String _authUserKey = 'auth_user';

  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoading = false;
  bool _isReady = false;
  late final Future<void> _restoreFuture;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _restoreFuture = _restoreAuthData();
  }

  Future<void> ensureInitialized() => _restoreFuture;

  Future<void> _restoreAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_authTokenKey);

    final storedUser = prefs.getString(_authUserKey);
    if (storedUser != null) {
      try {
        final decodedUser = jsonDecode(storedUser);
        if (decodedUser is Map<String, dynamic>) {
          _user = decodedUser;
        } else if (decodedUser is Map) {
          _user = decodedUser.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        await prefs.remove(_authUserKey);
      }
    }

    _isReady = true;
    notifyListeners();

    if (_token != null) {
      unawaited(_refreshUserProfile(prefs));
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.login(email, password);
      _token = response.data['token']?.toString();
      _user = _mapUserData(response.data['user']);

      await _persistAuthData();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e) ??
          AppStrings.current.tr('auth.loginFailed');
    }
  }

  Future<String?> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.register(name, email, phone, password);
      _token = response.data['token']?.toString();
      _user = _mapUserData(response.data['user']);

      await _persistAuthData();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e) ??
          AppStrings.current.tr('auth.registrationFailed');
    }
  }

  Future<String?> forgotPassword(
    String email,
    String phone,
    String password,
    String passwordConfirmation,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.forgotPassword(
        email,
        phone,
        password,
        passwordConfirmation,
      );
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e) ??
          AppStrings.current.tr('auth.passwordResetFailed');
    }
  }

  Future<String?> updateProfile(String name, String email, String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.updateProfile(name, email, phone);
      _user = _mapUserData(response.data);
      await _persistAuthData();
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e) ??
          AppStrings.current.tr('profile.updateFailed');
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
        return AppStrings.current.tr(
          'auth.serverError',
          params: {'status': '$statusCode'},
        );
      }
    }

    if (error is DioException && error.response == null) {
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return AppStrings.current.tr(
            'auth.cannotReachServer',
            params: {'url': ApiService.baseUrl},
          );
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
      // Ignore API errors and always clear local auth state.
    }
    await _clearSession();
    notifyListeners();
  }

  Future<void> _refreshUserProfile([SharedPreferences? existingPrefs]) async {
    try {
      final response = await _apiService.getUser();
      _user = _mapUserData(response.data);
      await _persistAuthData(existingPrefs);
      notifyListeners();
    } catch (error) {
      if (_isUnauthorizedError(error)) {
        await _clearSession(existingPrefs);
        notifyListeners();
      }
    }
  }

  Map<String, dynamic>? _mapUserData(dynamic userData) {
    if (userData is Map<String, dynamic>) {
      return userData;
    }
    if (userData is Map) {
      return userData.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<void> _persistAuthData([SharedPreferences? existingPrefs]) async {
    final prefs = existingPrefs ?? await SharedPreferences.getInstance();

    if (_token != null && _token!.isNotEmpty) {
      await prefs.setString(_authTokenKey, _token!);
    } else {
      await prefs.remove(_authTokenKey);
    }

    if (_user != null) {
      await prefs.setString(_authUserKey, jsonEncode(_user));
    } else {
      await prefs.remove(_authUserKey);
    }
  }

  Future<void> _clearSession([SharedPreferences? existingPrefs]) async {
    final prefs = existingPrefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_authUserKey);
    _token = null;
    _user = null;
  }

  bool _isUnauthorizedError(Object error) {
    return error is DioException &&
        error.response != null &&
        (error.response!.statusCode == 401 ||
            error.response!.statusCode == 403);
  }
}

final authProvider = ChangeNotifierProvider<AuthProvider>(
  (ref) => AuthProvider(),
);
