import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../baseUrl.dart';
import 'notificaciones_servicio.dart';

class FirebaseNotificacionesServicio {
  static final FirebaseNotificacionesServicio _instance = FirebaseNotificacionesServicio._internal();
  factory FirebaseNotificacionesServicio() => _instance;
  FirebaseNotificacionesServicio._internal();

  static FirebaseMessaging? _messaging;
  static String? _token;
  static FlutterLocalNotificationsPlugin? _localNotifications;

  /// Inicializar Firebase y configurar notificaciones
  static Future<void> inicializar() async {
    try {
      print('🔥 Inicializando Firebase...');
      
      // Inicializar Firebase Core
      await Firebase.initializeApp();
      print('✅ Firebase Core inicializado');

      // Obtener instancia de Firebase Messaging
      _messaging = FirebaseMessaging.instance;
      
      // Inicializar notificaciones locales
      await _inicializarNotificacionesLocales();
      
      // Solicitar permisos
      await _solicitarPermisos();
      
      // Obtener token FCM
      await _obtenerToken();
      
      // Configurar listeners
      _configurarListeners();
      
      // Registrar token en backend
      await _registrarTokenEnBackend();
      
      print('🎉 Firebase Notificaciones configurado exitosamente');
      
    } catch (e) {
      print('❌ Error inicializando Firebase: $e');
    }
  }

  /// Solicitar permisos de notificación
  static Future<void> _solicitarPermisos() async {
    try {
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificación concedidos');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Permisos provisionales concedidos');
      } else {
        print('❌ Permisos de notificación denegados');
      }
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
    }
  }

  /// Obtener token FCM del dispositivo
  static Future<String?> _obtenerToken() async {
    try {
      _token = await _messaging!.getToken();
      print('🔑 Token FCM obtenido: ${_token?.substring(0, 20)}...');
      
      // Guardar token localmente
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('fcm_token', _token!);
      }
      
      return _token;
    } catch (e) {
      print('❌ Error obteniendo token FCM: $e');
      return null;
    }
  }

  /// Registrar token en el backend
  static Future<void> _registrarTokenEnBackend() async {
    try {
      if (_token == null) {
        print('⚠️ No hay token FCM para registrar');
        return;
      }

      // Obtener datos del usuario
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('usuario');
      
      if (userDataString == null) {
        print('⚠️ No hay datos de usuario para registrar token');
        return;
      }

      final userData = jsonDecode(userDataString);
      final userId = userData['id'];

      if (userId == null) {
        print('⚠️ No se encontró ID de usuario');
        return;
      }

      // Enviar token al backend
      final url = Uri.parse('$baseUrl/fcm/registrar-token/');
      print('🔗 URL completa: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'fcm_token': _token,
          'user_id': userId,
        }),
      ).timeout(Duration(seconds: 10)); // Timeout de 10 segundos

      print('📱 Respuesta del servidor: ${response.statusCode}');
      print('📱 Cuerpo de respuesta: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          print('✅ Token FCM registrado en backend exitosamente');
        } else {
          print('❌ Error registrando token: ${result['message']}');
        }
      } else if (response.statusCode == 301 || response.statusCode == 302) {
        print('⚠️ Redirección detectada. Verificar URL del endpoint.');
        print('🔗 Headers de respuesta: ${response.headers}');
      } else {
        print('❌ Error HTTP registrando token: ${response.statusCode}');
        print('❌ Cuerpo del error: ${response.body}');
      }

    } on TimeoutException catch (e) {
      print('⏱️ Timeout conectando al backend: $e');
      print('⚠️ Verifica que el backend esté corriendo en la IP correcta');
    } catch (e) {
      print('❌ Error registrando token en backend: $e');
    }
  }

  /// Configurar listeners para notificaciones
  static void _configurarListeners() {
    try {
      // Cuando la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 ==> NOTIFICACIÓN RECIBIDA EN PRIMER PLANO <==');
        print('Título: ${message.notification?.title}');
        print('Mensaje: ${message.notification?.body}');
        print('Data: ${message.data}');
        print('From: ${message.from}');
        print('MessageId: ${message.messageId}');
        
        _mostrarNotificacionLocal(message);
      });

      // Cuando se toca una notificación (app en background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔔 Notificación tocada (app en background):');
        print('Título: ${message.notification?.title}');
        print('Data: ${message.data}');
        
        _manejarNotificacionTocada(message);
      });

      // Cuando la app se abre desde una notificación (app cerrada)
      _messaging!.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('🚀 App abierta desde notificación:');
          print('Título: ${message.notification?.title}');
          print('Data: ${message.data}');
          
          _manejarNotificacionTocada(message);
        }
      });

      print('🎧 Listeners de notificaciones configurados');
      
    } catch (e) {
      print('❌ Error configurando listeners: $e');
    }
  }

  /// Inicializar notificaciones locales
  static Future<void> _inicializarNotificacionesLocales() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _localNotifications!.initialize(initializationSettings);
      
      // Crear canal de notificación para Android 8+
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notificaciones Importantes',
        description: 'Canal para notificaciones importantes de Trust Country',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      
      final androidPlugin = _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        print('✅ Canal de notificación creado: ${channel.id}');
      } else {
        print('⚠️ No se pudo crear el canal de notificación');
      }
      
      print('✅ Notificaciones locales inicializadas');
    } catch (e) {
      print('❌ Error inicializando notificaciones locales: $e');
    }
  }

  /// Mostrar notificación local cuando la app está en primer plano
  static Future<void> _mostrarNotificacionLocal(RemoteMessage message) async {
    try {
      print('🔔 Mostrando notificación local: ${message.notification?.title}');
      
      if (_localNotifications == null) {
        print('⚠️ Plugin de notificaciones locales no inicializado');
        return;
      }
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'Notificaciones Importantes',
        channelDescription: 'Canal para notificaciones importantes de Trust Country',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@drawable/ic_notification', // Ícono TC para barra de estado
        // largeIcon eliminado - no mostrar ícono grande de Flutter
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? 'Trust Country',
        message.notification?.body ?? 'Nueva notificación',
        platformChannelSpecifics,
      );
      
      print('✅ Notificación local mostrada exitosamente');
      
    } catch (e) {
      print('❌ Error mostrando notificación local: $e');
    }
  }

  /// Manejar cuando se toca una notificación
  static void _manejarNotificacionTocada(RemoteMessage message) {
    try {
      print('👆 Manejando notificación tocada');
      
      final tipo = message.data['tipo'];
      
      switch (tipo) {
        case 'cumpleanos':
          print('🎂 Navegando a pantalla de cumpleaños');
          // Aquí podrías navegar a una pantalla específica
          break;
        case 'cita':
          print('📅 Navegando a pantalla de citas');
          break;
        default:
          print('📱 Notificación general');
      }
      
    } catch (e) {
      print('❌ Error manejando notificación tocada: $e');
    }
  }

  /// Obtener token actual
  static Future<String?> obtenerToken() async {
    if (_token != null) return _token;
    return await _obtenerToken();
  }

  /// Verificar si las notificaciones están habilitadas
  static Future<bool> notificacionesHabilitadas() async {
    try {
      if (_messaging == null) return false;
      
      NotificationSettings settings = await _messaging!.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return false;
    }
  }

  /// Actualizar token en backend (llamar cuando cambie el usuario)
  static Future<void> actualizarTokenEnBackend() async {
    await _registrarTokenEnBackend();
  }

  /// Enviar notificación local de prueba
  static Future<void> enviarNotificacionLocal({required String titulo, required String mensaje}) async {
    try {
      if (_localNotifications == null) {
        print('⚠️ Notificaciones locales no inicializadas');
        return;
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        icon: '@drawable/ic_notification', // Ícono TC para barra de estado
        // largeIcon eliminado - no mostrar ícono grande de Flutter
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      await _localNotifications!.show(
        0,
        titulo,
        mensaje,
        platformChannelSpecifics,
      );
      
      print('✅ Notificación local enviada: $titulo');
    } catch (e) {
      print('❌ Error enviando notificación local: $e');
    }
  }
  
  /// Enviar notificación local con delay para prueba en segundo plano
  static Future<void> enviarNotificacionLocalConDelay({required String titulo, required String mensaje, required int segundosDelay}) async {
    try {
      print('🕒 Notificación programada para $segundosDelay segundos...');
      print('📱 Puedes minimizar la app ahora para probar notificaciones en segundo plano');
      
      // Esperar el tiempo especificado
      await Future.delayed(Duration(seconds: segundosDelay));
      
      // Enviar la notificación después del delay
      await enviarNotificacionLocal(titulo: titulo, mensaje: mensaje);
      
    } catch (e) {
      print('❌ Error enviando notificación con delay: $e');
    }
  }

  /// Método seguro para registrar desde pantallas existentes
  static Future<void> registrarTokenSeguro() async {
    try {
      if (_messaging == null) {
        print('⚠️ Firebase no está inicializado, omitiendo registro de token');
        return;
      }
      await _registrarTokenEnBackend();
      print('✅ Token FCM registrado desde pantalla');
    } catch (e) {
      print('⚠️ Error registrando token (no crítico): $e');
    }
  }
}

/// Handler para notificaciones en background (debe estar fuera de la clase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  print('🔔 Notificación en background recibida:');
  print('Título: ${message.notification?.title}');
  print('Mensaje: ${message.notification?.body}');
  print('Data: ${message.data}');
  
  // CRÍTICO: Android automáticamente muestra la notificación cuando la app está cerrada
  // Si el mensaje tiene notification payload, Android la mostrará automáticamente
  print('✅ Notificación procesada en background - Android la mostrará automáticamente');
}
