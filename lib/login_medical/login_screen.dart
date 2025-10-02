import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../welcome_screen.dart';
import 'screens_medical/home.dart';
import '../servicios/login_servicio.dart';
import '../servicios/session_preference_service.dart';
import '../servicios/preference_usuario.dart';
import 'referral_code_screen.dart';
import 'forgot_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  bool _isLoading = false;

  // Definimos las decoraciones de forma estática para evitar recreaciones
  static const _inputBorderRadius = BorderRadius.all(Radius.circular(12));

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
    // Obtener el ThemeProvider para acceder al estado del modo oscuro
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.darkModeEnabled;
    
    // Definir colores según el tema
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);
    final hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    
    // Colores de la aplicación
    final inputFillColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50]!;

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
                          color: isDarkMode ? Colors.grey[800] : Colors.black,
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/logotipo.jpg',
                                    height: 120,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Medical Appointments',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    '¡Bienvenido!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: isDarkMode ? const Color.fromARGB(255, 108, 170, 240) : Color(0xFF2D3142),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Espero que estés bien.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white : const Color.fromARGB(255, 108, 170, 240),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Your Email',
                                      labelStyle: TextStyle(color: hintColor),
                                      floatingLabelStyle: const TextStyle(color: Color(0xFF4485FD)),
                                      filled: true,
                                      fillColor: inputFillColor,
                                      border: OutlineInputBorder(
                                        borderRadius: _inputBorderRadius,
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: _inputBorderRadius,
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: _inputBorderRadius,
                                        borderSide: const BorderSide(color: Color(0xFF4485FD), width: 2),
                                      ),
                                      prefixIcon: Icon(Icons.email_outlined, color: hintColor),
                                    ),
                                    style: TextStyle(color: textColor),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(color: hintColor),
                                      floatingLabelStyle: const TextStyle(color: Color(0xFF4485FD)),
                                      filled: true,
                                      fillColor: inputFillColor,
                                      border: OutlineInputBorder(
                                        borderRadius: _inputBorderRadius,
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: _inputBorderRadius,
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: _inputBorderRadius,
                                        borderSide: const BorderSide(color: Color(0xFF4485FD), width: 2),
                                      ),
                                      prefixIcon: Icon(Icons.lock_outline, color: hintColor),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: hintColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    style: TextStyle(color: textColor),
                                  ),
                                  const SizedBox(height: 24),
                                  // Sign In Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : loginUser,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4485FD),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                        disabledBackgroundColor: const Color(0xFF4485FD).withOpacity(0.6),
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
                                      Expanded(child: Divider(color: borderColor)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'or',
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: borderColor)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Social Login Buttons
                                  
                                  
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
                                        color: const Color(0xFF4485FD),
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
                                              builder: (context) => const ReferralCodeScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Regístrate',
                                          style: TextStyle(
                                            color: const Color(0xFF4485FD),
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
                            ),
                          ],
                        ),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4485FD)),
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
    
    print('📊 RESPUESTA LOGIN MEDICAL: ${response['success']}');

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

      // GUARDAR DATOS EN LAS CLAVES CORRECTAS DE MEDICAL
      final data = response['data'];
      await guardarDatosUsuarioMedical(data['token'], data['user']);
      
      // Guardar que el usuario eligió Medical manualmente
      await SessionPreferenceService.saveUserManualChoice('medical');
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
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
