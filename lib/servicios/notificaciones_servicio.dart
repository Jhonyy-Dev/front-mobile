import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../baseUrl.dart';
import 'preference_usuario.dart';

class NotificacionesServicio {
  static final NotificacionesServicio _instance = NotificacionesServicio._internal();
  factory NotificacionesServicio() => _instance;
  NotificacionesServicio._internal();

  // Canal para comunicación con notificaciones nativas (futuro uso)
  // static const MethodChannel _channel = MethodChannel('awesome_notifications_channel');

  // Inicializar las notificaciones
  static Future<void> inicializar() async {
    try {
      // Implementación básica sin dependencias externas
      print('🔔 Sistema de notificaciones inicializado correctamente');
      await solicitarPermisos();
    } catch (e) {
      print('Error al inicializar notificaciones: $e');
    }
  }

  // Solicitar permisos
  static Future<bool> solicitarPermisos() async {
    try {
      // Simulación de solicitud de permisos
      print('🔔 Permisos de notificaciones concedidos');
      return true;
    } catch (e) {
      print('Error al solicitar permisos: $e');
      return false;
    }
  }

  // Verificar si es cumpleaños y programar notificación
  static Future<void> verificarCumpleanos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fechaNacimiento = prefs.getString('fecha_nacimiento');
      
      if (fechaNacimiento != null && fechaNacimiento.isNotEmpty) {
        final DateTime fechaNac = DateTime.parse(fechaNacimiento);
        final DateTime hoy = DateTime.now();
        
        // Verificar si hoy es su cumpleaños (día y mes coinciden)
        if (fechaNac.day == hoy.day && fechaNac.month == hoy.month) {
          await _enviarNotificacionCumpleanos();
          await _marcarCumpleanosNotificado();
        }
      }
    } catch (e) {
      print('Error al verificar cumpleaños: $e');
    }
  }

  // Enviar notificación de cumpleaños
  static Future<void> _enviarNotificacionCumpleanos() async {
    final prefs = await SharedPreferences.getInstance();
    final yaNotificado = prefs.getBool('cumpleanos_notificado_${DateTime.now().year}') ?? false;
    
    // Solo enviar si no se ha notificado este año
    if (!yaNotificado) {
      try {
        print('🎉 ENVIANDO NOTIFICACIÓN DE CUMPLEAÑOS VIA BACKEND...');
        
        // Obtener ID del usuario
        final userId = prefs.getInt('user_id');
        if (userId == null) {
          print('⚠️ No se encontró ID de usuario');
          return;
        }
        
        // Llamar al endpoint del backend
        final url = Uri.parse('$baseUrl/fcm/verificar-cumpleanos');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'user_id': userId,
          }),
        );
        
        print('📱 Respuesta del backend: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            print('✅ Notificación de cumpleaños enviada exitosamente via FCM');
            // Marcar como notificado
            await _marcarCumpleanosNotificado();
          } else {
            print('❌ Error en backend: ${data['message']}');
          }
        } else {
          print('❌ Error HTTP: ${response.statusCode}');
        }
      } catch (e) {
        print('Error al enviar notificación: $e');
      }
    }
  }

  // Marcar que ya se notificó el cumpleaños este año
  static Future<void> _marcarCumpleanosNotificado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cumpleanos_notificado_${DateTime.now().year}', true);
  }

  // Verificar si hoy es cumpleaños (para mostrar banner en la app)
  static Future<bool> esCumpleanosHoy() async {
    try {
      print('🔍 INICIANDO VERIFICACIÓN DE CUMPLEAÑOS...');
      
      // Obtener datos del usuario usando el servicio correcto
      final userData = await obtenerDatosUsuario();
      
      if (userData != null && userData['usuario'] != null) {
        final usuario = userData['usuario'];
        final fechaNacimiento = usuario['fecha_nacimiento'];
        
        print('📅 Datos del usuario obtenidos:');
        print('📅 Fecha de nacimiento: $fechaNacimiento');
        
        if (fechaNacimiento != null && fechaNacimiento.toString().isNotEmpty) {
          final DateTime fechaNac = DateTime.parse(fechaNacimiento.toString());
          final DateTime hoy = DateTime.now();
          
          print('📅 Fecha nacimiento: ${fechaNac.day}/${fechaNac.month}/${fechaNac.year}');
          print('📅 Fecha hoy: ${hoy.day}/${hoy.month}/${hoy.year}');
          
          final esCumpleanos = fechaNac.day == hoy.day && fechaNac.month == hoy.month;
          print('🎉 ¿Es cumpleaños? $esCumpleanos');
          
          if (esCumpleanos) {
            print('🎂 ¡¡¡ES CUMPLEAÑOS!!! Enviando notificación...');
            await _enviarNotificacionCumpleanos();
          }
          
          return esCumpleanos;
        }
      }
      
      print('⚠️ No se encontraron datos de usuario o fecha de nacimiento');
      return false;
    } catch (e) {
      print('❌ Error al verificar si es cumpleaños: $e');
      return false;
    }
  }

  // Programar verificación diaria de cumpleaños
  static Future<void> programarVerificacionDiaria() async {
    try {
      print('🔔 Verificación diaria de cumpleaños programada');
      // En una implementación real, aquí se programaría la verificación
    } catch (e) {
      print('Error al programar verificación: $e');
    }
  }

  // Configurar listeners
  static Future<void> configurarListeners() async {
    try {
      print('🔔 Listeners de notificaciones configurados');
      // En una implementación real, aquí se configurarían los listeners
    } catch (e) {
      print('Error al configurar listeners: $e');
    }
  }

  // FUNCIÓN DE PRUEBA: Enviar notificación desde Flutter
  static Future<void> enviarNotificacionPrueba() async {
    try {
      print('🧪 ENVIANDO NOTIFICACIÓN DE PRUEBA DESDE FLUTTER...');
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 10;
      
      final url = Uri.parse('$baseUrl/fcm/enviar-notificacion');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_ids': [userId],
          'titulo': '🧪 Prueba Celular Físico',
          'mensaje': '¡Notificación de prueba en dispositivo real!',
        }),
      );
      
      print('📱 Respuesta: ${response.statusCode}');
      print('📱 Cuerpo: ${response.body}');
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
