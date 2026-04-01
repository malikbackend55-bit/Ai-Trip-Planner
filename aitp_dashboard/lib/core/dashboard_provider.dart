import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _stats = {};
  List<dynamic> _users = [];
  List<dynamic> _trips = [];
  Map<String, dynamic> _adminProfile = {};
  bool _isLoading = false;

  // Filter / search state
  String _tripFilter = 'All Trips';
  String _userFilter = 'All';
  String _catalogFilter = 'All';
  String _tripSearchQuery = '';
  String _userSearchQuery = '';
  String _catalogSearchQuery = '';

  Map<String, dynamic> get stats => _stats;
  List<dynamic> get users => _users;
  List<dynamic> get trips => _trips;
  Map<String, dynamic> get adminProfile => _adminProfile;
  bool get isLoading => _isLoading;

  String get tripFilter => _tripFilter;
  String get userFilter => _userFilter;
  String get catalogFilter => _catalogFilter;
  String get tripSearchQuery => _tripSearchQuery;
  String get userSearchQuery => _userSearchQuery;
  String get catalogSearchQuery => _catalogSearchQuery;

  String displayTripStatus(dynamic trip) {
    if (trip is! Map) {
      return 'Upcoming';
    }

    final tripMap = Map<String, dynamic>.from(trip);
    final rawStatus = (tripMap['status'] ?? '').toString().trim().toLowerCase();

    if (rawStatus == 'cancelled' || rawStatus == 'canceled') {
      return 'Cancelled';
    }

    if (rawStatus == 'completed' || rawStatus == 'past') {
      return 'Completed';
    }

    if (rawStatus == 'upcoming' || rawStatus == 'scheduled' || rawStatus == 'in progress') {
      return 'Upcoming';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime.tryParse(tripMap['end_date']?.toString() ?? '');

    if (endDate != null) {
      final endDay = DateTime(endDate.year, endDate.month, endDate.day);
      if (endDay.isBefore(today)) {
        return 'Completed';
      }
    }

    return 'Upcoming';
  }

  int get completedTripCount =>
      _trips.where((trip) => displayTripStatus(trip) == 'Completed').length;

  // Filtered getters
  List<dynamic> get filteredTrips {
    var result = _trips;

    // Apply status filter
    if (_tripFilter != 'All Trips') {
      result = result.where((t) {
        return displayTripStatus(t) == _tripFilter;
      }).toList();
    }

    // Apply search
    if (_tripSearchQuery.isNotEmpty) {
      final q = _tripSearchQuery.toLowerCase();
      result = result.where((t) =>
          (t['destination'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  List<dynamic> get filteredUsers {
    var result = _users;

    // Apply role filter
    if (_userFilter != 'All') {
      result = result.where((u) {
        final role = (u['role'] ?? 'user').toString().toLowerCase();
        return role == _userFilter.toLowerCase();
      }).toList();
    }

    // Apply search
    if (_userSearchQuery.isNotEmpty) {
      final q = _userSearchQuery.toLowerCase();
      result = result.where((u) =>
          (u['name'] ?? '').toString().toLowerCase().contains(q) ||
          (u['email'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  List<dynamic> get filteredCatalog {
    var result = _trips; // Catalog uses trips as source

    // Apply filter
    if (_catalogFilter == 'Featured') {
      result = result.where((t) =>
          (double.tryParse(t['budget']?.toString() ?? '0') ?? 0) >= 2000).toList();
    } else if (_catalogFilter == 'Hidden') {
      result = result.where((t) => displayTripStatus(t) == 'Cancelled').toList();
    }

    // Apply search
    if (_catalogSearchQuery.isNotEmpty) {
      final q = _catalogSearchQuery.toLowerCase();
      result = result.where((t) =>
          (t['destination'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  // Computed user stats
  int get premiumUserCount => _users.where((u) =>
      (u['role'] ?? '').toString().toLowerCase() == 'premium').length;

  int get adminUserCount => _users.where((u) =>
      (u['role'] ?? '').toString().toLowerCase() == 'admin').length;

  int get activeUserCount => _users.length; // All users count as active for now

  // Filter setters
  void setTripFilter(String filter) {
    _tripFilter = filter;
    notifyListeners();
  }

  void setUserFilter(String filter) {
    _userFilter = filter;
    notifyListeners();
  }

  void setCatalogFilter(String filter) {
    _catalogFilter = filter;
    notifyListeners();
  }

  void setTripSearchQuery(String query) {
    _tripSearchQuery = query;
    notifyListeners();
  }

  void setUserSearchQuery(String query) {
    _userSearchQuery = query;
    notifyListeners();
  }

  void setCatalogSearchQuery(String query) {
    _catalogSearchQuery = query;
    notifyListeners();
  }

  void clearSession() {
    _stats = {};
    _users = [];
    _trips = [];
    _adminProfile = {};
    _isLoading = false;
    _tripFilter = 'All Trips';
    _userFilter = 'All';
    _catalogFilter = 'All';
    _tripSearchQuery = '';
    _userSearchQuery = '';
    _catalogSearchQuery = '';
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final statsRes = await _apiService.getAdminStats();
      final usersRes = await _apiService.getAdminUsers();
      final tripsRes = await _apiService.getTrips();
      
      _stats = statsRes.data;
      _users = usersRes.data;
      _trips = tripsRes.data;

      try {
        final profileRes = await _apiService.getAdminProfile();
        _adminProfile = profileRes.data is Map<String, dynamic> ? profileRes.data : {};
      } catch (_) {
        // Profile fetch failed, keep existing
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      await _apiService.deleteUser(id);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTrip(int id) async {
    try {
      await _apiService.deleteTrip(id);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createAdmin(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.createAdmin(name, email, password);
      await refresh();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserRole(int id, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.updateUserRole(id, role);
      await refresh();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

final dashboardProvider = ChangeNotifierProvider<DashboardProvider>((ref) => DashboardProvider());
