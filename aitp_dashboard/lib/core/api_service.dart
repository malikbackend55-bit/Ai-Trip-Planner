import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session.dart';

class ApiService {
  static const String _retryBaseUrlIndexKey = 'retryBaseUrlIndex';
  static const String _coolifyDomain =
      'owkgkkwckg0www4s4c0oww8s.45.32.155.226.sslip.io';
  static const String _coolifyDomainApiUrl = 'http://$_coolifyDomain/api';
  static const String _coolifyIpApiUrl = 'http://45.32.155.226/api';
  late Dio dio;
  late final List<_ApiEndpoint> _baseUrls;
  String? _hostHeader;

  ApiService() {
    _baseUrls = _candidateBaseUrls;
    final initialEndpoint = _baseUrls.first;
    _hostHeader = initialEndpoint.hostHeader;

    dio = Dio(
      BaseOptions(
        baseUrl: initialEndpoint.baseUrl,
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
          if (_hostHeader != null) {
            options.headers['Host'] = _hostHeader;
          } else {
            options.headers.remove('Host');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final retried = await _retryWithFallback(error);
          if (retried != null) {
            return handler.resolve(retried);
          }

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

  static List<_ApiEndpoint> get _candidateBaseUrls {
    final urls = <_ApiEndpoint>[];

    void addUrl(String url, {String? hostHeader}) {
      final normalized = _normalizeApiUrl(url);
      final endpoint = _ApiEndpoint(normalized, hostHeader: hostHeader);
      final exists = urls.any(
        (candidate) =>
            candidate.baseUrl == endpoint.baseUrl &&
            candidate.hostHeader == endpoint.hostHeader,
      );
      if (normalized.isNotEmpty && !exists) {
        urls.add(endpoint);
      }
    }

    const configuredUrl = String.fromEnvironment('API_URL');
    if (configuredUrl.isNotEmpty) {
      addUrl(configuredUrl);
    }

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      final isLocalHost =
          host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';

      if (isLocalHost) {
        addUrl('http://127.0.0.1:8000/api');
        addUrl('http://127.0.0.1:8001/api');
        addUrl('http://localhost:8000/api');
        addUrl('http://localhost:8001/api');
      }

      addUrl('${Uri.base.origin}/api');

      return urls;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      addUrl('http://10.0.2.2:8000/api');
      addUrl('http://10.0.2.2:8001/api');
      addUrl(_coolifyIpApiUrl, hostHeader: _coolifyDomain);
      return urls;
    }

    addUrl('http://127.0.0.1:8000/api');
    addUrl('http://127.0.0.1:8001/api');
    addUrl('http://localhost:8000/api');
    addUrl('http://localhost:8001/api');
    addUrl(_coolifyDomainApiUrl);
    return urls;
  }

  static String _normalizeApiUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final withoutTrailingSlash = trimmed.replaceFirst(RegExp(r'/+$'), '');
    if (withoutTrailingSlash.endsWith('/api')) {
      return withoutTrailingSlash;
    }

    return '$withoutTrailingSlash/api';
  }

  Future<Response<dynamic>?> _retryWithFallback(DioException error) async {
    final currentIndex =
        error.requestOptions.extra[_retryBaseUrlIndexKey] as int? ?? 0;

    if (!_shouldRetryWithFallback(error, currentIndex)) {
      return null;
    }

    final nextIndex = currentIndex + 1;
    final nextEndpoint = _baseUrls[nextIndex];
    final headers = Map<String, dynamic>.from(error.requestOptions.headers);
    if (nextEndpoint.hostHeader != null) {
      headers['Host'] = nextEndpoint.hostHeader;
    } else {
      headers.remove('Host');
    }

    final requestOptions = error.requestOptions.copyWith(
      baseUrl: nextEndpoint.baseUrl,
      headers: headers,
      extra: <String, dynamic>{
        ...error.requestOptions.extra,
        _retryBaseUrlIndexKey: nextIndex,
      },
    );

    try {
      final response = await dio.fetch<dynamic>(requestOptions);
      dio.options.baseUrl = nextEndpoint.baseUrl;
      _hostHeader = nextEndpoint.hostHeader;
      return response;
    } on DioException {
      return null;
    }
  }

  bool _shouldRetryWithFallback(DioException error, int currentIndex) {
    if (currentIndex >= _baseUrls.length - 1) {
      return false;
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    return error.response?.statusCode == 404;
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

class _ApiEndpoint {
  final String baseUrl;
  final String? hostHeader;

  const _ApiEndpoint(this.baseUrl, {this.hostHeader});
}
