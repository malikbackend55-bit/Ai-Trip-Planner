import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class TripProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _trips = [];
  bool _isLoading = false;

  List<dynamic> get trips => _trips;
  bool get isLoading => _isLoading;

  Future<void> fetchTrips() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getTrips();
      _trips = response.data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching trips: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateTrip(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.generateTrip(data);
      await fetchTrips();
      _isLoading = false;
      notifyListeners();
      return null; // Success, no error
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> updateTrip(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.updateTrip(id, data);
      await fetchTrips();
      _isLoading = false;
      notifyListeners();
      return null;
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _extractErrorMessage(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<bool> deleteTrip(int id) async {
    try {
      await _apiService.deleteTrip(id);
      await fetchTrips();
      return true;
    } catch (e) {
      debugPrint('Error deleting trip: $e');
      return false;
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) return data['message'];
        if (data.containsKey('error')) return data['error'];
      }
    }
    return 'A network error occurred: ${e.message}';
  }
}

final tripProvider = ChangeNotifierProvider<TripProvider>((ref) => TripProvider());
