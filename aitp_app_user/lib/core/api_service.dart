import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio dio;
  static const String baseUrl = 'http://localhost:5001/api';

  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
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

  Future<Response> register(String name, String email, String password) async {
    return dio.post('/register', data: {
      'name': name,
      'email': email,
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
}
