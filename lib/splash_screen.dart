import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'login_migration/screens_migration/home.dart' as migration;
import 'login_medical/screens_medical/home.dart' as medical;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    try {
      print('🔍 Verificando sesión activa...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar si hay datos de usuario guardados
      final usuarioData = prefs.getString('usuario');
      final usuarioMedicalData = prefs.getString('usuario_medical');
      final token = prefs.getString('token');
      final tokenMedical = prefs.getString('token_medical');
      
      // Delay mínimo para mostrar splash
      await Future.delayed(Duration(milliseconds: 1500));
      
      if (mounted) {
        // Verificar sesión de Migration
        if (usuarioData != null && token != null && usuarioData.isNotEmpty && token.isNotEmpty) {
          print('✅ Sesión Migration activa encontrada');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const migration.HomePage()),
          );
          return;
        }
        
        // Verificar sesión de Medical
        if (usuarioMedicalData != null && tokenMedical != null && usuarioMedicalData.isNotEmpty && tokenMedical.isNotEmpty) {
          print('✅ Sesión Medical activa encontrada');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const medical.HomePage()),
          );
          return;
        }
        
        // No hay sesión activa, ir a WelcomeScreen
        print('⚠️ No hay sesión activa, mostrando WelcomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
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
