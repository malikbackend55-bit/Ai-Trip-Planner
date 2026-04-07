import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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
        onError: (DioException e, handler) {
          // Handle global errors like 401 Unauthorized
          if (e.response?.statusCode == 401) {
            // Could trigger logout here
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Auth Methods
  Future<Response> login(String email, String password) async {
    return dio.post('/login', data: {'email': email, 'password': password});
  }

  Future<Response> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    return dio.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
  }

  Future<Response> forgotPassword(
    String email,
    String phone,
    String password,
    String passwordConfirmation,
  ) async {
    return dio.post(
      '/forgot-password',
      data: {
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  // Trip Methods
  Future<Response> getTrips() async {
    return dio.get('/trips');
  }

  Future<Response> createTrip(Map<String, dynamic> data) async {
    return dio.post('/trips', data: data);
  }

  Future<Response> updateTrip(int id, Map<String, dynamic> data) async {
    return dio.put('/trips/$id', data: data);
  }

  Future<Response> generateTrip(Map<String, dynamic> data) async {
    return dio.post('/trips/generate', data: data);
  }

  // User Profile
  Future<Response> getUser() async {
    return dio.get('/user');
  }

  Future<Response> logout() async {
    return dio.post('/logout');
  }

  Future<Response> deleteTrip(int id) async {
    return dio.delete('/trips/$id');
  }

  Future<Response> getDestinations() async {
    return dio.get('/admin/stats');
  }
}
