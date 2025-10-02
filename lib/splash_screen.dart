import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'login_migration/screens_migration/home.dart' as migration;
import 'login_medical/screens_medical/home.dart' as medical;
import 'servicios/session_preference_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print('🚀 SPLASH SCREEN INICIADO - initState()');
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      print('🚀 _checkSession() EJECUTÁNDOSE...');
      print('🔍 Verificando sesión activa...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar si hay datos de usuario guardados
      final usuarioData = prefs.getString('usuario');
      final usuarioMedicalData = prefs.getString('usuario_medical');
      final token = prefs.getString('token');
      final tokenMedical = prefs.getString('token_medical');
      
      // DEBUG DETALLADO
      print('🔍 DEBUG COMPLETO:');
      print('   usuarioData: ${usuarioData?.substring(0, usuarioData.length > 50 ? 50 : usuarioData.length)}...');
      print('   usuarioMedicalData: ${usuarioMedicalData?.substring(0, usuarioMedicalData != null && usuarioMedicalData.length > 50 ? 50 : usuarioMedicalData?.length ?? 0)}...');
      print('   token: ${token?.substring(0, token.length > 20 ? 20 : token.length)}...');
      print('   tokenMedical: ${tokenMedical?.substring(0, tokenMedical != null && tokenMedical.length > 20 ? 20 : tokenMedical.length)}...');
      
      // Delay mínimo para mostrar splash
      await Future.delayed(Duration(milliseconds: 1500));
      
      if (mounted) {
        // Usar el nuevo servicio para verificar sesiones
        final sessions = await SessionPreferenceService.checkActiveSessions();
        final hasMigrationSession = sessions['migration'] ?? false;
        final hasMedicalSession = sessions['medical'] ?? false;
        
        // Obtener la última elección manual del usuario con múltiples métodos
        final lastManualChoice = await SessionPreferenceService.getUserManualChoice();
        
        // Método de respaldo directo
        String? emergencyChoice;
        try {
          final prefs = await SharedPreferences.getInstance();
          emergencyChoice = prefs.getString('emergency_choice');
          print('🆘 Elección de emergencia: $emergencyChoice');
        } catch (e) {
          print('❌ Error leyendo elección de emergencia: $e');
        }
        
        // Usar la elección que esté disponible
        final finalChoice = lastManualChoice ?? emergencyChoice;
        print('🎯 ELECCIÓN FINAL DETERMINADA: $finalChoice');
        
        print('🎯 LÓGICA DE SESIÓN:');
        print('   Migration activa: $hasMigrationSession');
        print('   Medical activa: $hasMedicalSession');
        print('   Última elección manual: $lastManualChoice');
        
        // LÓGICA CORREGIDA: RESPETAR SIEMPRE LA ELECCIÓN MANUAL
        if (hasMigrationSession && hasMedicalSession) {
          // Ambas sesiones - usar elección manual
          if (finalChoice == 'medical') {
            print('✅ RESULTADO: Abriendo Medical (elección manual)');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const medical.HomePage()),
            );
          } else if (finalChoice == 'migration') {
            print('✅ RESULTADO: Abriendo Migration (elección manual)');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const migration.HomePage()),
            );
          } else {
            // Sin elección previa - Medical por defecto
            print('✅ RESULTADO: Abriendo Medical (sin elección previa)');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const medical.HomePage()),
            );
          }
          return;
        }
        
        // NUEVA LÓGICA: SI HAY ELECCIÓN MANUAL, RESPETARLA AUNQUE NO HAYA SESIÓN
        if (finalChoice != null) {
          if (finalChoice == 'medical' && hasMedicalSession) {
            print('✅ RESULTADO: Respetando elección Medical (con sesión)');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const medical.HomePage()),
            );
            return;
          } else if (finalChoice == 'migration' && hasMigrationSession) {
            print('✅ RESULTADO: Respetando elección Migration (con sesión)');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const migration.HomePage()),
            );
            return;
          } else {
            // Elección manual pero sin sesión correspondiente - ir a login
            print('⚠️ CONFLICTO: Elección $finalChoice pero sin sesión correspondiente');
            print('→ Redirigiendo a WelcomeScreen para re-login');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
            return;
          }
        }
        
        // Solo una sesión activa SIN elección manual previa
        if (hasMedicalSession && !hasMigrationSession) {
          print('✅ RESULTADO: Solo Medical activa (sin elección previa)');
          await SessionPreferenceService.saveUserManualChoice('medical');
          print('💾 GUARDADO AUTOMÁTICO: Medical como única sesión');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const medical.HomePage()),
          );
          return;
        }
        
        if (hasMigrationSession && !hasMedicalSession) {
          print('✅ RESULTADO: Solo Migration activa (sin elección previa)');
          await SessionPreferenceService.saveUserManualChoice('migration');
          print('💾 GUARDADO AUTOMÁTICO: Migration como única sesión');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const migration.HomePage()),
          );
          return;
        }
        
        // No hay sesión activa, ir a WelcomeScreen
        print('⚠️ No hay sesión activa, mostrando WelcomeScreen');
        print('🚀 INTENTANDO NAVEGAR A WELCOMESCREEN...');
        try {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
          print('✅ NAVEGACIÓN A WELCOMESCREEN EXITOSA');
        } catch (e) {
          print('❌ ERROR EN NAVEGACIÓN A WELCOMESCREEN: $e');
        }
      }
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/medical-migration.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'TC',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A9B7F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'TrustCountry',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Health & Legal Care',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
