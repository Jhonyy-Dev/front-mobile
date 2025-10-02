import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../welcome_screen.dart';
import 'screens_migration/home.dart';
import 'package:mi_app_flutter/login_medical/forgot_password_screen.dart';
import 'referral_code_screen.dart';
import '../providers/theme_provider.dart';
import '../servicios/login_servicio.dart';
import '../servicios/session_preference_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Definimos las decoraciones de forma estática para evitar recreaciones
  static const _inputBorderRadius = BorderRadius.all(Radius.circular(12));
  
  static final _defaultBorder = OutlineInputBorder(
    borderRadius: _inputBorderRadius,
  );
  
  static final _focusedBorder = OutlineInputBorder(
    borderRadius: _inputBorderRadius,
    borderSide: const BorderSide(color: Color(0xFF4A9B7F), width: 2),
  );

  static const _floatingLabelStyle = TextStyle(color: Color(0xFF4A9B7F));

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    // Definir colores dinámicos basados en el modo oscuro
    final Color backgroundColor = darkModeEnabled ? Color(0xFF121212) : Colors.white;
    final Color primaryTextColor = darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = darkModeEnabled ? Color(0xFFB0B3B8) : Colors.grey[600]!;
    final Color iconBackgroundColor = darkModeEnabled ? Colors.grey[800]! : Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Botón de retroceso
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: iconBackgroundColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView(
                          children: [
                            const SizedBox(height: 16),
                            Image.asset(
                              'assets/logotipo.jpg',
                              height: 120,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inmigration Appointments',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                color: primaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '¡Bienvenido!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inicia sesión para continuar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Your Email',
                                labelStyle: TextStyle(color: secondaryTextColor),
                                floatingLabelStyle: _floatingLabelStyle,
                                border: _defaultBorder,
                                focusedBorder: _focusedBorder,
                                prefixIcon: Icon(Icons.email_outlined, color: secondaryTextColor),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: secondaryTextColor),
                                floatingLabelStyle: _floatingLabelStyle,
                                border: _defaultBorder,
                                focusedBorder: _focusedBorder,
                                prefixIcon: Icon(Icons.lock_outline, color: secondaryTextColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: secondaryTextColor,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: loginUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A9B7F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Or divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: secondaryTextColor)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'O',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: secondaryTextColor)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                '¿Has olvidado tu contraseña?',
                                style: TextStyle(
                                  color: const Color(0xFF4A9B7F),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿No tienes una cuenta? ',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReferralCodeScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Regístrate',
                                    style: TextStyle(
                                      color: Color(0xFF4A9B7F),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ],
                        ),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9B7F)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese email y contraseña'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    AuthService authService = AuthService();
    final response = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicio de sesión exitoso'),
          backgroundColor: Colors.green,
        ),
      );

      // FORZAR GUARDADO DE ELECCIÓN MIGRATION
      print('🔵 EJECUTANDO GUARDADO MIGRATION - INICIO');
      try {
        await SessionPreferenceService.saveUserManualChoice('migration');
        print('🔵 EJECUTANDO GUARDADO MIGRATION - EXITOSO');
      } catch (e) {
        print('🔵 ERROR EN GUARDADO MIGRATION: $e');
        // Método de respaldo directo
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('emergency_choice', 'migration');
          print('🔵 GUARDADO DE EMERGENCIA MIGRATION EXITOSO');
        } catch (e2) {
          print('🔵 FALLO TOTAL MIGRATION: $e2');
        }
      }
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const HomePage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
