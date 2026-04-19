import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app_localization.dart';

class TripNotificationService {
  TripNotificationService._();

  static final TripNotificationService instance = TripNotificationService._();

  static const String _channelId = 'trip_daily_reminders';
  static const String _channelName = 'Trip reminders';
  static const String _channelDescription = 'Daily reminders for active trips';
  static const String _scheduledIdsKey = 'trip_notification_ids';
  static const int _reminderHour = 8;
  static const int _reminderMinute = 0;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> ensureInitialized() async {
    if (_isInitialized || kIsWeb) {
      return;
    }

    tz.initializeTimeZones();

    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(initializationSettings);
    await _requestPermissions();
    _isInitialized = true;
  }

  Future<void> syncActiveTripReminders(List<dynamic> trips) async {
    if (kIsWeb) {
      return;
    }

    await ensureInitialized();
    await cancelTripReminders();

    final todayNow = DateTime.now();
    final today = DateTime(todayNow.year, todayNow.month, todayNow.day);
    final scheduledIds = <int>[];

    for (final rawTrip in trips) {
      final trip = _mapTrip(rawTrip);
      if (trip == null) {
        continue;
      }

      final tripId = int.tryParse(trip['id']?.toString() ?? '');
      final startDate = _parseDate(trip['start_date']);
      final endDate = _parseDate(trip['end_date']);

      if (tripId == null || startDate == null || endDate == null) {
        continue;
      }

      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      if (today.isAfter(end)) {
        continue;
      }

      final firstReminderDate = today.isAfter(start) ? today : start;

      for (
        var day = firstReminderDate;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      ) {
        final scheduledAt = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          _reminderHour,
          _reminderMinute,
        );

        if (scheduledAt.isBefore(tz.TZDateTime.now(tz.local))) {
          continue;
        }

        final dayNumber = day.difference(start).inDays + 1;
        final notificationId = (tripId * 1000) + dayNumber;
        final destination =
            (trip['destination'] ??
                    AppStrings.current.tr('common.unknownDestination'))
                .toString();

        await _notifications.zonedSchedule(
          notificationId,
          AppStrings.current.tr(
            'tripReminder.title',
            params: {'destination': destination},
          ),
          AppStrings.current.tr(
            'tripReminder.body',
            params: {'day': '$dayNumber'},
          ),
          scheduledAt,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );

        scheduledIds.add(notificationId);
      }
    }

    await _persistScheduledIds(scheduledIds);
  }

  Future<void> cancelTripReminders() async {
    if (kIsWeb) {
      return;
    }

    await ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_scheduledIdsKey) ?? const [];

    for (final value in savedIds) {
      final id = int.tryParse(value);
      if (id != null) {
        await _notifications.cancel(id);
      }
    }

    await prefs.remove(_scheduledIdsKey);
  }

  Future<void> _persistScheduledIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scheduledIdsKey,
      ids.map((value) => value.toString()).toList(),
    );
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Map<String, dynamic>? _mapTrip(dynamic rawTrip) {
    if (rawTrip is Map<String, dynamic>) {
      return rawTrip;
    }

    if (rawTrip is Map) {
      return rawTrip.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  DateTime? _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
