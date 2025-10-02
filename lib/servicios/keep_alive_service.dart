import 'package:flutter/services.dart';

class KeepAliveService {
  static const MethodChannel _channel = MethodChannel('keep_alive_service');

  /// Iniciar el servicio foreground para mantener notificaciones activas
  static Future<bool> startKeepAliveService() async {
    try {
      final result = await _channel.invokeMethod('startKeepAliveService');
      print('✅ Servicio Keep Alive iniciado: $result');
      return result ?? false;
    } catch (e) {
      print('❌ Error iniciando Keep Alive Service: $e');
      return false;
    }
  }

  /// Detener el servicio foreground
  static Future<bool> stopKeepAliveService() async {
    try {
      final result = await _channel.invokeMethod('stopKeepAliveService');
      print('🛑 Servicio Keep Alive detenido: $result');
      return result ?? false;
    } catch (e) {
      print('❌ Error deteniendo Keep Alive Service: $e');
      return false;
    }
  }

  /// Verificar si el servicio está ejecutándose
  static Future<bool> isKeepAliveServiceRunning() async {
    try {
      final result = await _channel.invokeMethod('isKeepAliveServiceRunning');
      return result ?? false;
    } catch (e) {
      print('❌ Error verificando Keep Alive Service: $e');
      return false;
    }
  }
}
