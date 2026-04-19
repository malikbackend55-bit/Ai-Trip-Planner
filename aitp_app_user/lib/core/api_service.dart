import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio dio;
  static const String _localDesktopApiUrl = 'http://127.0.0.1:8000/api';
  static const String _localAndroidEmulatorApiUrl = 'http://10.0.2.2:8000/api';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _chatTimeout = Duration(seconds: 75);
  static const Duration _tripGenerationTimeout = Duration(minutes: 4);

  static String get _configuredBaseUrl {
    const String apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }

    if (kIsWeb) {
      return _localDesktopApiUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _localAndroidEmulatorApiUrl;
    }

    return _localDesktopApiUrl;
  }

  static String get baseUrl {
    return _configuredBaseUrl;
  }

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
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

  Future<Response> sendChat(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    return dio.post(
      '/chat',
      data: {'message': message, 'context': context},
      options: Options(sendTimeout: _chatTimeout, receiveTimeout: _chatTimeout),
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
    return dio.post(
      '/trips/generate',
      data: data,
      options: Options(
        sendTimeout: _tripGenerationTimeout,
        receiveTimeout: _tripGenerationTimeout,
      ),
    );
  }

  // User Profile
  Future<Response> getUser() async {
    return dio.get('/user');
  }

  Future<Response> updateProfile(
    String name,
    String email,
    String phone,
  ) async {
    return dio.put(
      '/user',
      data: {'name': name, 'email': email, 'phone': phone},
    );
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
