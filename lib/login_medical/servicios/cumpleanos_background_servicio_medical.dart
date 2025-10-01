import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../baseUrl.dart';
import '../../servicios/firebase_notificaciones_servicio.dart';

class CumpleanosBackgroundServicioMedical {
  static const String TASK_NAME = "verificar_cumpleanos_diario_medical";
  
  /// Inicializar WorkManager y programar verificación diaria
  static Future<void> inicializar() async {
    try {
      await Workmanager().initialize(
        callbackDispatcherMedical,
        isInDebugMode: false, // Cambiar a false en producción
      );
      
      // Programar verificación diaria a las 00:00:01 AM (inicio del día)
      await programarVerificacionDiaria();
      
      print('🎂 Servicio de cumpleaños MEDICAL en segundo plano inicializado');
    } catch (e) {
      print('❌ Error inicializando servicio de cumpleaños MEDICAL: $e');
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
      
      print('📅 Verificación diaria de cumpleaños MEDICAL programada para las 00:00:01 AM');
    } catch (e) {
      print('❌ Error programando verificación diaria MEDICAL: $e');
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
      print('🎂 Verificando cumpleaños MEDICAL en segundo plano...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener datos del usuario MEDICAL
      final userDataString = prefs.getString('usuario_medical');
      if (userDataString == null) {
        print('⚠️ No hay datos de usuario MEDICAL en segundo plano');
        return;
      }
      
      final userData = jsonDecode(userDataString);
      final fechaNacimiento = userData['fecha_nacimiento'];
      final userId = userData['id'];
      final nombreCompleto = userData['nombre'] ?? 'Usuario';
      // Extraer solo el primer nombre
      final nombreUsuario = nombreCompleto.split(' ').first;
      
      if (fechaNacimiento == null || userId == null) {
        print('⚠️ Faltan datos de cumpleaños o ID de usuario MEDICAL');
        return;
      }
      
      // Verificar si es cumpleaños
      final DateTime fechaNac = DateTime.parse(fechaNacimiento);
      final DateTime hoy = DateTime.now();
      
      print('📅 Verificando MEDICAL: ${fechaNac.day}/${fechaNac.month} vs ${hoy.day}/${hoy.month}');
      
      if (fechaNac.day == hoy.day && fechaNac.month == hoy.month) {
        // ¡ES CUMPLEAÑOS!
        print('🎉 ¡ES CUMPLEAÑOS DE $nombreUsuario (MEDICAL)!');
        
        // Verificar si ya se notificó este año
        final yaNotificado = prefs.getBool('cumpleanos_notificado_medical_${hoy.year}') ?? false;
        
        if (!yaNotificado) {
          // Enviar notificación local
          await _enviarNotificacionCumpleanosLocal(nombreUsuario);
          
          // Enviar notificación a través del backend
          await _enviarNotificacionCumpleanosBackend(userId);
          
          // Marcar como notificado
          await prefs.setBool('cumpleanos_notificado_medical_${hoy.year}', true);
          
          print('✅ Notificación de cumpleaños MEDICAL enviada exitosamente');
        } else {
          print('ℹ️ Ya se envió notificación de cumpleaños MEDICAL este año');
        }
      } else {
        print('📅 No es cumpleaños hoy (MEDICAL)');
      }
    } catch (e) {
      print('❌ Error verificando cumpleaños MEDICAL en segundo plano: $e');
    }
  }
  
  /// Enviar notificación local de cumpleaños
  static Future<void> _enviarNotificacionCumpleanosLocal(String nombre) async {
    try {
      await FirebaseNotificacionesServicio.enviarNotificacionLocal(
        titulo: '🎉 ¡Feliz Cumpleaños $nombre!',
        mensaje: '¡Que pases un día súper hermoso con tus seres amados! ❤️✨',
      );
    } catch (e) {
      print('❌ Error enviando notificación local de cumpleaños MEDICAL: $e');
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
          'tipo': 'medical', // Identificar que es usuario médico
        }),
      ).timeout(Duration(seconds: 30));
      
      print('📱 Respuesta backend cumpleaños MEDICAL: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Notificación de cumpleaños MEDICAL enviada via backend');
        }
      }
    } catch (e) {
      print('❌ Error enviando notificación backend MEDICAL: $e');
    }
  }
  
  /// Cancelar todas las tareas programadas
  static Future<void> cancelarTareas() async {
    try {
      await Workmanager().cancelByUniqueName(TASK_NAME);
      print('🛑 Tareas de cumpleaños MEDICAL canceladas');
    } catch (e) {
      print('❌ Error cancelando tareas MEDICAL: $e');
    }
  }
}

/// Callback dispatcher para WorkManager MEDICAL
@pragma('vm:entry-point')
void callbackDispatcherMedical() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 Ejecutando tarea MEDICAL en segundo plano: $task');
      
      switch (task) {
        case CumpleanosBackgroundServicioMedical.TASK_NAME:
          await CumpleanosBackgroundServicioMedical.verificarCumpleanosBackground();
          break;
        default:
          print('⚠️ Tarea MEDICAL desconocida: $task');
      }
      
      return Future.value(true);
    } catch (e) {
      print('❌ Error en callback dispatcher MEDICAL: $e');
      return Future.value(false);
    }
  });
}
