import 'package:flutter/material.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default is Dark Mode

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _saveThemeMode(mode);
  }

  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> loadThemeMode() async {
    // For MVP: Theme preference can be simulated or read from local memory
    // Defaults to ThemeMode.dark
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    // Simulated local persistence hook
  }
}

// Global single instance for access across settings and widget trees
final ThemeManager themeManager = ThemeManager();
