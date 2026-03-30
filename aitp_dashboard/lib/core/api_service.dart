import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio dio;
  static String get baseUrl {
    const String apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }
    return 'http://localhost:8000/api';
  }

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
    ));
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

  Future<Response> deleteUser(int id) async {
    return dio.delete('/admin/users/$id');
  }

  Future<Response> deleteTrip(int id) async {
    return dio.delete('/admin/trips/$id');
  }

  Future<Response> getAdminProfile() async {
    return dio.get('/user');
  }

  Future<Response> createAdmin(String name, String email, String password) async {
    return dio.post('/admin/users', data: {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<Response> updateUserRole(int id, String role) async {
    return dio.put('/admin/users/$id/role', data: {
      'role': role,
    });
  }
}
