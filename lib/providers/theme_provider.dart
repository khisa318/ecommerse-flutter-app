import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themePreferenceKey = 'isDarkMode';

  final SharedPreferences sharedPreferences;
  bool _isDarkMode;

  ThemeProvider({
    required this.sharedPreferences,
  }) : _isDarkMode =
            sharedPreferences.getBool(_themePreferenceKey) ?? false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await sharedPreferences.setBool(_themePreferenceKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) {
      return;
    }
    _isDarkMode = value;
    await sharedPreferences.setBool(_themePreferenceKey, _isDarkMode);
    notifyListeners();
  }
}
