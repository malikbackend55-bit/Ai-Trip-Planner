import 'package:flutter/material.dart';
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generateTrip(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.generateTrip(data);
      await fetchTrips();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
