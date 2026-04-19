import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'api_service.dart';
import 'app_settings_provider.dart';
import 'app_localization.dart';
import 'trip_notification_service.dart';

class TripProvider extends ChangeNotifier {
  TripProvider(this._ref);

  final ApiService _apiService = ApiService();
  final Ref _ref;
  List<dynamic> _trips = [];
  bool _isLoading = false;

  List<dynamic> get trips => _trips;
  bool get isLoading => _isLoading;

  void clearTrips() {
    _trips = [];
    _isLoading = false;
    unawaited(TripNotificationService.instance.cancelTripReminders());
    notifyListeners();
  }

  Future<void> fetchTrips() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getTrips();
      _trips = _normalizeTrips(response.data);
      await syncNotifications();
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

  Future<void> syncNotifications() async {
    try {
      await _ref.read(appSettingsProvider.notifier).ensureLoaded();
      final settings = _ref.read(appSettingsProvider);

      if (!settings.notificationsEnabled) {
        await TripNotificationService.instance.cancelTripReminders();
        return;
      }

      await TripNotificationService.instance.syncActiveTripReminders(_trips);
    } catch (e) {
      debugPrint('Error syncing trip notifications: $e');
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.type == DioExceptionType.receiveTimeout) {
      return AppStrings.current.tr('trip.timeout');
    }

    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) return data['message'];
        if (data.containsKey('error')) return data['error'];
      }
    }
    return AppStrings.current.tr(
      'trip.networkError',
      params: {'message': e.message ?? ''},
    );
  }

  List<dynamic> _normalizeTrips(dynamic rawTrips) {
    if (rawTrips is! List) {
      return [];
    }

    final normalized = rawTrips.map((rawTrip) {
      final trip = _mapTrip(rawTrip);
      trip['status'] = _resolveStatus(trip);
      return trip;
    }).toList();

    normalized.sort((a, b) {
      final statusComparison = _statusPriority(
        a['status']?.toString() ?? '',
      ).compareTo(_statusPriority(b['status']?.toString() ?? ''));

      if (statusComparison != 0) {
        return statusComparison;
      }

      final aDate = _parseDate(a['start_date']) ?? DateTime(9999);
      final bDate = _parseDate(b['start_date']) ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });

    return normalized;
  }

  Map<String, dynamic> _mapTrip(dynamic rawTrip) {
    if (rawTrip is Map<String, dynamic>) {
      return Map<String, dynamic>.from(rawTrip);
    }

    if (rawTrip is Map) {
      return rawTrip.map((key, value) => MapEntry(key.toString(), value));
    }

    return <String, dynamic>{};
  }

  String _resolveStatus(Map<String, dynamic> trip) {
    final startDate = _parseDate(trip['start_date']);
    final endDate = _parseDate(trip['end_date']);
    final persistedStatus = trip['status']?.toString().trim();

    if (startDate == null || endDate == null) {
      return persistedStatus?.isNotEmpty == true
          ? persistedStatus!
          : 'Upcoming';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (today.isBefore(start)) {
      return 'Upcoming';
    }

    if (today.isAfter(end)) {
      return 'Past';
    }

    return 'Active';
  }

  DateTime? _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }

  int _statusPriority(String status) => switch (status.toLowerCase()) {
    'active' => 0,
    'upcoming' => 1,
    'past' || 'completed' => 2,
    _ => 3,
  };
}

final tripProvider = ChangeNotifierProvider<TripProvider>(
  (ref) => TripProvider(ref),
);
