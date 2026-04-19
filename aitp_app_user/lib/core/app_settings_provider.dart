import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppSettingsState {
  const AppSettingsState({
    this.isLoaded = false,
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  final bool isLoaded;
  final bool notificationsEnabled;
  final ThemeMode themeMode;

  AppSettingsState copyWith({
    bool? isLoaded,
    bool? notificationsEnabled,
    ThemeMode? themeMode,
  }) {
    return AppSettingsState(
      isLoaded: isLoaded ?? this.isLoaded,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(const AppSettingsState());

  static const String _notificationsKey = 'settings.notifications.enabled';
  static const String _themeModeKey = 'settings.theme_mode';

  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeModeKey);

    state = state.copyWith(
      isLoaded: true,
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      themeMode: switch (savedThemeMode) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      },
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    });
    state = state.copyWith(themeMode: mode);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
      (ref) => AppSettingsNotifier(),
    );
