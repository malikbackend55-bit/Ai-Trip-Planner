import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session.dart';

class ApiService {
  late Dio dio;
  static const String _coolifyDomain =
      'owkgkkwckg0www4s4c0oww8s.45.32.155.226.sslip.io';
  static const String _coolifyDomainApiUrl = 'http://$_coolifyDomain/api';
  static const String _coolifyIpApiUrl = 'http://45.32.155.226/api';

  static String get _configuredBaseUrl {
    const String apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }

    if (kIsWeb) {
      return Uri.base.resolve('/api').toString();
    }

    return _coolifyDomainApiUrl;
  }

  static bool get _useAndroidHostHeaderWorkaround {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final uri = Uri.tryParse(_configuredBaseUrl);
    return uri != null && uri.scheme == 'http' && uri.host == _coolifyDomain;
  }

  static String get baseUrl {
    if (_useAndroidHostHeaderWorkaround) {
      return _coolifyIpApiUrl;
    }

    return _configuredBaseUrl;
  }

  static String? get hostHeader {
    if (_useAndroidHostHeaderWorkaround) {
      return _coolifyDomain;
    }

    return null;
  }

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          final host = hostHeader;
          if (host != null) {
            options.headers['Host'] = host;
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            authSession.markSessionExpired();
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> login(String email, String password) async {
    return dio.post('/login', data: {'email': email, 'password': password});
  }

  Future<Response> getAdminStats() async {
    return dio.get('/admin/stats');
  }

  Future<Response> getAdminUsers() async {
    return dio.get('/admin/users');
  }

  Future<Response> getTrips() async {
    return dio.get('/admin/trips');
  }

  Future<Response> createTrip(Map<String, dynamic> data) async {
    return dio.post('/admin/trips', data: data);
  }

  Future<Response> updateTrip(int id, Map<String, dynamic> data) async {
    return dio.put('/admin/trips/$id', data: data);
  }

  Future<Response> exportAdminData() async {
    return dio.get('/admin/export');
  }

  Future<Response> resetAdminData() async {
    return dio.post('/admin/reset');
  }

  Future<Response> deleteUser(int id) async {
    return dio.delete('/admin/users/$id');
  }

  Future<Response> deleteTrip(int id) async {
    return dio.delete('/admin/trips/$id');
  }

  Future<Response> getAdminProfile() async {
    return dio.get('/user');
  }

  Future<Response> createAdmin(
    String name,
    String email,
    String password,
  ) async {
    return dio.post(
      '/admin/users',
      data: {'name': name, 'email': email, 'password': password},
    );
  }

  Future<Response> updateUserRole(int id, String role) async {
    return dio.put('/admin/users/$id/role', data: {'role': role});
  }
}
