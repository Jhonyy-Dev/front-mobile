import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _darkModeKey = 'dark_mode_enabled';

  // Guardar el estado del modo oscuro
  Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDarkMode);
  }

  // Obtener el estado del modo oscuro
  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }
}
