import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localization.dart';

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.sorani) {
    AppStrings.currentLanguage = state;
  }

  static const String _prefsKey = 'app_language';

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final language = saved == AppLanguage.english.storageValue
        ? AppLanguage.english
        : AppLanguage.sorani;

    state = language;
    AppStrings.currentLanguage = language;
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.storageValue);
    state = language;
    AppStrings.currentLanguage = language;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
  (ref) => LanguageNotifier(),
);
