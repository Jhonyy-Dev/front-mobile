import 'package:flutter/material.dart';
import 'package:mi_app_flutter/servicios/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _darkModeEnabled = false;
  final ThemeService _themeService = ThemeService();

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get darkModeEnabled => _darkModeEnabled;

  Future<void> _loadThemePreference() async {
    _darkModeEnabled = await _themeService.isDarkMode();
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _darkModeEnabled = value;
    await _themeService.setDarkMode(value);
    notifyListeners();
  }
}
