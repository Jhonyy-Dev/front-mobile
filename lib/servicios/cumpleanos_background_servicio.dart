import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../baseUrl.dart';
import 'fcm_backend_servicio.dart';
import 'firebase_notificaciones_servicio.dart';

class CumpleanosBackgroundServicio {
  static const String TASK_NAME = "verificar_cumpleanos_diario";
  
  /// Inicializar WorkManager y programar verificación diaria
  static Future<void> inicializar() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Cambiar a false en producción
      );
      
      // Programar verificación diaria a las 00:00:01 AM (inicio del día)
      await programarVerificacionDiaria();
      
      print('🎂 Servicio de cumpleaños en segundo plano inicializado');
    } catch (e) {
      print('❌ Error inicializando servicio de cumpleaños: $e');
    }
  }
  
  /// Programar verificación diaria de cumpleaños
  static Future<void> programarVerificacionDiaria() async {
    try {
      // Cancelar tareas anteriores
      await Workmanager().cancelByUniqueName(TASK_NAME);
      
      // Programar nueva tarea diaria
      await Workmanager().registerPeriodicTask(
        TASK_NAME,
        TASK_NAME,
        frequency: Duration(hours: 24), // Cada 24 horas
        initialDelay: _calcularDelayHastaMedianoche(),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      print('📅 Verificación diaria de cumpleaños programada para las 00:00:01 AM');
    } catch (e) {
      print('❌ Error programando verificación diaria: $e');
    }
  }
  
  /// Calcular delay hasta las 00:00:01 AM del próximo día (inicio del cumpleaños)
  static Duration _calcularDelayHastaMedianoche() {
    final now = DateTime.now();
    // Programar para las 00:00:01 AM del próximo día
    var nextRun = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    
    return nextRun.difference(now);
  }
  
  /// Verificar cumpleaños en segundo plano
  static Future<void> verificarCumpleanosBackground() async {
    try {
      print('🎂 Verificando cumpleaños en segundo plano...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener datos del usuario
      final userDataString = prefs.getString('usuario');
      if (userDataString == null) {
        print('⚠️ No hay datos de usuario en segundo plano');
        return;
      }
      
      final userData = jsonDecode(userDataString);
      final fechaNacimiento = userData['fecha_nacimiento'];
      final userId = userData['id'];
      final nombreCompleto = userData['nombre'] ?? 'Usuario';
      // Extraer solo el primer nombre
      final nombreUsuario = nombreCompleto.split(' ').first;
      
      if (fechaNacimiento == null || userId == null) {
        print('⚠️ Faltan datos de cumpleaños o ID de usuario');
        return;
      }
      
      // Verificar si es cumpleaños
      final DateTime fechaNac = DateTime.parse(fechaNacimiento);
      final DateTime hoy = DateTime.now();
      
      print('📅 Verificando: ${fechaNac.day}/${fechaNac.month} vs ${hoy.day}/${hoy.month}');
      
      if (fechaNac.day == hoy.day && fechaNac.month == hoy.month) {
        // ¡ES CUMPLEAÑOS!
        
        // Verificar si ya se notificó este año
        final yaNotificado = prefs.getBool('cumpleanos_notificado_${hoy.year}') ?? false;
        
        if (!yaNotificado) {
          // Enviar notificación local y al backend
          await _enviarNotificacionCumpleanosLocal(nombreUsuario);
          await _enviarNotificacionCumpleanosBackend(userId);
          
          // IMPORTANTE: Solicitar al backend que envíe FCM (funciona con app cerrada)
          await FCMBackendServicio.solicitarNotificacionCumpleanos(userId, nombreUsuario);
          
          // Marcar como notificado
          await prefs.setBool('cumpleanos_notificado_${hoy.year}', true);
          
        } else {
          print('ℹ️ Ya se envió notificación de cumpleaños este año');
        }
      } else {
        print('📅 No es cumpleaños hoy');
      }
    } catch (e) {
      print('❌ Error verificando cumpleaños en segundo plano: $e');
    }
  }
  
  /// Enviar notificación local de cumpleaños
  static Future<void> _enviarNotificacionCumpleanosLocal(String nombre) async {
    try {
      // Primero intentar notificación local (si la app está abierta)
      await FirebaseNotificacionesServicio.enviarNotificacionLocal(
        titulo: '🎉 ¡Feliz Cumpleaños $nombre!',
        mensaje: '¡Que pases un día súper hermoso con tus seres amados! ❤️✨',
      );
      
      print('✅ Notificación local de cumpleaños enviada para $nombre');
    } catch (e) {
      print('❌ Error enviando notificación local de cumpleaños: $e');
    }
  }
  
  /// Enviar notificación a través del backend
  static Future<void> _enviarNotificacionCumpleanosBackend(int userId) async {
    try {
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
      ).timeout(Duration(seconds: 30));
      
      print('📱 Respuesta backend cumpleaños: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Notificación de cumpleaños enviada via backend');
        }
      }
    } catch (e) {
      print('❌ Error enviando notificación backend: $e');
    }
  }
  
  /// Cancelar todas las tareas programadas
  static Future<void> cancelarTareas() async {
    try {
      await Workmanager().cancelByUniqueName(TASK_NAME);
      print('🛑 Tareas de cumpleaños canceladas');
    } catch (e) {
      print('❌ Error cancelando tareas: $e');
    }
  }
}

/// Callback dispatcher para WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 Ejecutando tarea en segundo plano: $task');
      
      switch (task) {
        case CumpleanosBackgroundServicio.TASK_NAME:
          await CumpleanosBackgroundServicio.verificarCumpleanosBackground();
          break;
        default:
          print('⚠️ Tarea desconocida: $task');
      }
      
      return Future.value(true);
    } catch (e) {
      print('❌ Error en callback dispatcher: $e');
      return Future.value(false);
    }
  });
}
