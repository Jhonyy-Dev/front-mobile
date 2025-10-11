import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'servicios/cumpleanos_background_servicio.dart';
import 'login_medical/servicios/cumpleanos_background_servicio_medical.dart';
import 'servicios/fcm_backend_servicio.dart';
import 'servicios/firebase_notificaciones_servicio.dart';
import 'servicios/notificaciones_servicio.dart';
import 'services/video_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Reducir verbosidad de logs (filtrar logs nativos de Android)
  debugPrint = (String? message, {int? wrapWidth}) {
    // Filtrar logs molestos de MediaCodec/BufferPool
    if (message != null && 
        (message.contains('MediaCodec') ||
         message.contains('BufferPool') ||
         message.contains('CCodec') ||
         message.contains('Codec2') ||
         message.contains('PipelineWatcher') ||
         message.contains('ImageReader_JNI'))) {
      return; // Silenciar estos logs
    }
    // Imprimir otros logs normalmente
    print(message);
  };
  
  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  
  // Inicializar Firebase y notificaciones push (con manejo de errores)
  try {
    await FirebaseNotificacionesServicio.inicializar();
    
    // Configurar handler para notificaciones en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('⚠️ Firebase no se pudo inicializar: $e');
    print('📱 La app funcionará sin notificaciones push');
  }
  
  // Inicializar notificaciones locales (banner)
  await NotificacionesServicio.inicializar();
  await NotificacionesServicio.configurarListeners();
  await NotificacionesServicio.solicitarPermisos();
  
  // Inicializar servicios de cumpleaños en segundo plano para AMBAS versiones
  try {
    // Servicio para usuarios de MIGRACIÓN
    await CumpleanosBackgroundServicio.inicializar();
    print('🎂 Servicio de cumpleaños MIGRATION activado');
    
    // Servicio para usuarios MÉDICOS
    await CumpleanosBackgroundServicioMedical.inicializar();
    print('🎂 Servicio de cumpleaños MEDICAL activado');
    
    // Registrar token FCM en backend para notificaciones push
    await FCMBackendServicio.registrarTokenFCM();
    await FCMBackendServicio.configurarNotificacionesProgramadas();
    
  } catch (e) {
    print('⚠️ Error inicializando servicios de cumpleaños: $e');
  }
  
  // Precargar video de fondo (para que aparezca instantáneamente)
  try {
    print('🎬 Precargando video de fondo...');
    await VideoManager().initialize();
    print('✅ Video de fondo listo');
  } catch (e) {
    print('⚠️ Error precargando video: $e');
  }
  
  // Firebase initialization commented out for iOS compatibility
  // if (kIsWeb) {
  //   try {
  //     await Firebase.initializeApp(
  //       options: const FirebaseOptions(
  //         apiKey: "YOUR_API_KEY",
  //         authDomain: "YOUR_AUTH_DOMAIN",
  //         projectId: "YOUR_PROJECT_ID",
  //         storageBucket: "YOUR_STORAGE_BUCKET",
  //         messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  //         appId: "YOUR_APP_ID",
  //       ),
  //     );
  //   } catch (e) {
  //     print('Failed to initialize Firebase: $e');
  //     // Continue without Firebase for development
  //   }
  // } else {
  //   await Firebase.initializeApp();
  // }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: const Color(0xFF4A9B7F),
              scaffoldBackgroundColor: Colors.white,
              fontFamily: 'Poppins',
              brightness: themeProvider.darkModeEnabled ? Brightness.dark : Brightness.light,
            ),
            home: const SplashScreen(),
          );
        }
      ),
    );
  }
}