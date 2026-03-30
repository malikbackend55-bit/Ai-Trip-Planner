import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio dio;
  static String get baseUrl {
    const String apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }
    
    // Fallback for local development
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api';
      }
    } catch (_) {
      // Platform check fails on Web
    }
    return 'http://localhost:8000/api';
  }

  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.add(InterceptorsWrapper(
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
    ));
  }

  // Auth Methods
  Future<Response> login(String email, String password) async {
    return dio.post('/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(String name, String email, String phone, String password) async {
    return dio.post('/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }

  // Trip Methods
  Future<Response> getTrips() async {
    return dio.get('/trips');
  }

  Future<Response> createTrip(Map<String, dynamic> data) async {
    return dio.post('/trips', data: data);
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
