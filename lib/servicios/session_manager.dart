import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyLastSection = 'last_active_section';
  static const String _keyLastRoute = 'last_active_route';
  
  /// Guardar la sección activa del usuario
  static Future<void> saveLastSection(String section) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSection, section);
      print('💾 Sección guardada: $section');
    } catch (e) {
      print('❌ Error guardando sección: $e');
    }
  }
  
  /// Obtener la última sección activa
  static Future<String?> getLastSection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final section = prefs.getString(_keyLastSection);
      print('📖 Sección recuperada: $section');
      return section;
    } catch (e) {
      print('❌ Error recuperando sección: $e');
      return null;
    }
  }
  
  /// Guardar la ruta específica donde se quedó
  static Future<void> saveLastRoute(String route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastRoute, route);
      print('💾 Ruta guardada: $route');
    } catch (e) {
      print('❌ Error guardando ruta: $e');
    }
  }
  
  /// Obtener la última ruta activa
  static Future<String?> getLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final route = prefs.getString(_keyLastRoute);
      print('📖 Ruta recuperada: $route');
      return route;
    } catch (e) {
      print('❌ Error recuperando ruta: $e');
      return null;
    }
  }
  
  /// Limpiar datos de sesión
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastSection);
      await prefs.remove(_keyLastRoute);
      print('🗑️ Sesión limpiada');
    } catch (e) {
      print('❌ Error limpiando sesión: $e');
    }
  }
}
