import 'package:shared_preferences/shared_preferences.dart';

class SessionPreferenceService {
  static const String _keyLastManualChoice = 'last_manual_session_choice';
  
  /// Guardar la elección manual del usuario (solo cuando hace login)
  static Future<void> saveUserManualChoice(String section) async {
    try {
      print('🔄 INICIANDO GUARDADO: $section');
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar con múltiples claves para asegurar persistencia
      await prefs.setString(_keyLastManualChoice, section);
      await prefs.setString('user_last_choice', section); // Clave alternativa
      await prefs.setInt('choice_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      // Verificar que se guardó correctamente
      final verificacion = prefs.getString(_keyLastManualChoice);
      final verificacion2 = prefs.getString('user_last_choice');
      
      print('🎯 GUARDADO EXITOSO:');
      print('   Sección: $section');
      print('   Verificación 1: $verificacion');
      print('   Verificación 2: $verificacion2');
      print('   Timestamp: ${DateTime.now().millisecondsSinceEpoch}');
      
      if (verificacion != section) {
        throw Exception('FALLO EN VERIFICACIÓN: No se guardó correctamente');
      }
    } catch (e) {
      print('❌ ERROR CRÍTICO guardando elección manual: $e');
      // Intentar método alternativo
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('backup_choice', section);
        print('💾 Guardado en clave de respaldo');
      } catch (e2) {
        print('❌ FALLO TOTAL: $e2');
      }
    }
  }
  
  /// Obtener la última elección manual del usuario
  static Future<String?> getUserManualChoice() async {
    try {
      print('🔍 INICIANDO LECTURA de elección manual...');
      final prefs = await SharedPreferences.getInstance();
      
      // Intentar leer de múltiples claves
      final choice1 = prefs.getString(_keyLastManualChoice);
      final choice2 = prefs.getString('user_last_choice');
      final backup = prefs.getString('backup_choice');
      final timestamp = prefs.getInt('choice_timestamp');
      
      print('📊 RESULTADOS DE LECTURA:');
      print('   Clave principal: $choice1');
      print('   Clave alternativa: $choice2');
      print('   Clave respaldo: $backup');
      print('   Timestamp: $timestamp');
      
      // Usar la primera que no sea null
      final finalChoice = choice1 ?? choice2 ?? backup;
      print('📖 ELECCIÓN FINAL: $finalChoice');
      
      return finalChoice;
    } catch (e) {
      print('❌ Error leyendo elección manual: $e');
      return null;
    }
  }
  
  /// Limpiar la elección manual (cuando el usuario hace logout)
  static Future<void> clearUserManualChoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastManualChoice);
      print('🗑️ Elección manual limpiada');
    } catch (e) {
      print('❌ Error limpiando elección manual: $e');
    }
  }
  
  /// Verificar si hay sesiones activas
  static Future<Map<String, bool>> checkActiveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final usuarioMedicalData = prefs.getString('usuario_medical');
      final tokenMedical = prefs.getString('token_medical');
      final token = prefs.getString('token');
      
      final hasMedical = (usuarioMedicalData != null && tokenMedical != null && 
                        usuarioMedicalData.isNotEmpty && tokenMedical.isNotEmpty) ||
                        (token != null && token.isNotEmpty);
      
      print('🔍 SESIONES ACTIVAS:');
      print('   Medical: $hasMedical');
      
      return {
        'migration': false,
        'medical': hasMedical,
      };
    } catch (e) {
      print('❌ Error verificando sesiones: $e');
      return {'migration': false, 'medical': false};
    }
  }
}
