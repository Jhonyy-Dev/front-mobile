import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('battery_optimization');

  /// Solicitar al usuario que desactive la optimización de batería
  static Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      // Solicitar permiso para ignorar optimización de batería
      final result = await _channel.invokeMethod('requestIgnoreBatteryOptimization');
      print('🔋 Resultado optimización batería: $result');
      return result ?? false;
    } catch (e) {
      print('❌ Error solicitando optimización batería: $e');
      return false;
    }
  }

  /// Verificar si la app está exenta de optimización de batería
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      print('❌ Error verificando optimización batería: $e');
      return false;
    }
  }

  /// Solicitar permisos críticos para notificaciones
  static Future<void> requestCriticalPermissions() async {
    try {
      // Solicitar permiso de notificaciones
      await Permission.notification.request();
      
      // Solicitar ignorar optimización de batería
      await requestIgnoreBatteryOptimization();
      
      print('✅ Permisos críticos solicitados');
    } catch (e) {
      print('❌ Error solicitando permisos críticos: $e');
    }
  }
}
