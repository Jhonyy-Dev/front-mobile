import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../baseUrl.dart';

class FCMBackendServicio {
  
  /// Registrar token FCM en el backend para notificaciones push
  static Future<bool> registrarTokenFCM() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener token FCM del dispositivo
      final fcmToken = prefs.getString('fcm_token');
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No hay token FCM disponible');
        return false;
      }
      
      // Obtener datos del usuario (Migration o Medical)
      String? userDataString = prefs.getString('usuario');
      String? token = prefs.getString('token');
      
      if (userDataString == null) {
        // Intentar con usuario medical
        userDataString = prefs.getString('usuario_medical');
        token = prefs.getString('token_medical');
      }
      
      if (userDataString == null || token == null) {
        print('⚠️ No hay datos de usuario para registrar token FCM');
        return false;
      }
      
      final userData = jsonDecode(userDataString);
      final userId = userData['id'];
      
      // Enviar token al backend (usando endpoint existente)
      final url = Uri.parse('$baseUrl/fcm/registrar-token/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': fcmToken,
          'device_type': 'android',
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Token FCM registrado en backend exitosamente');
        return true;
      } else {
        print('❌ Error registrando token FCM: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('❌ Error en registrarTokenFCM: $e');
      return false;
    }
  }
  
  /// Solicitar al backend que envíe notificación de cumpleaños
  static Future<bool> solicitarNotificacionCumpleanos(int userId, String nombre) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        token = prefs.getString('token_medical');
      }
      
      if (token == null) {
        print('⚠️ No hay token de autenticación');
        return false;
      }
      
      final url = Uri.parse('$baseUrl/fcm/verificar-cumpleanos');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'nombre': nombre,
          'titulo': '🎉 ¡Feliz Cumpleaños $nombre!',
          'mensaje': '¡Que pases un día súper hermoso con tus seres amados! ❤️✨',
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Solicitud de notificación FCM enviada al backend');
        return true;
      } else {
        print('❌ Error solicitando notificación FCM: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('❌ Error en solicitarNotificacionCumpleanos: $e');
      return false;
    }
  }
  
  /// Configurar notificaciones programadas en el backend
  static Future<bool> configurarNotificacionesProgramadas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener datos del usuario
      String? userDataString = prefs.getString('usuario');
      String? token = prefs.getString('token');
      
      if (userDataString == null) {
        userDataString = prefs.getString('usuario_medical');
        token = prefs.getString('token_medical');
      }
      
      if (userDataString == null || token == null) {
        print('⚠️ No hay datos de usuario para configurar notificaciones');
        return false;
      }
      
      final userData = jsonDecode(userDataString);
      final userId = userData['id'];
      final fechaNacimiento = userData['fecha_nacimiento'];
      
      if (fechaNacimiento == null) {
        print('⚠️ No hay fecha de nacimiento para configurar notificaciones');
        return false;
      }
      
      final url = Uri.parse('$baseUrl/fcm/verificar-cumpleanos');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'fecha_nacimiento': fechaNacimiento,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Notificaciones de cumpleaños configuradas en backend');
        return true;
      } else {
        print('❌ Error configurando notificaciones: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('❌ Error en configurarNotificacionesProgramadas: $e');
      return false;
    }
  }
}
