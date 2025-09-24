import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'login_medical/login_screen.dart' as medical;
import 'login_migration/login_screen.dart' as migration;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatelessWidget {
  // URL de la política de privacidad
  final String _privacyPolicyURL = 'https://v0-mobile-privacy-policy.vercel.app/';
  
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/welcome_bg.webp'),
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Health & Legal Care',
                    style: textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(text: '#1 In '),
                        TextSpan(
                          text: 'United',
                          style: TextStyle(color: Color.fromARGB(255, 108, 208, 255)),
                        ),
                        TextSpan(text: ' States'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Which section would you\n like to go to?',
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const medical.LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/salud.png',
                                  width: 24,
                                  height: 24,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Medical appointments',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const migration.LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4485FD),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/law.png',
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Migration Appointments',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showTermsOfServiceModal(context);
                            },
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchPrivacyPolicyURL();
                            },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método para abrir la URL de la política de privacidad
  Future<void> _launchPrivacyPolicyURL() async {
    final Uri url = Uri.parse(_privacyPolicyURL);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  // Método para mostrar el modal de Términos de Servicio
  void _showTermsOfServiceModal(BuildContext context) {
    // Definir colores para el modal
    final Color primaryColor = const Color(0xFF4485FD);
    final Color backgroundColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF1A1A1A) 
        : Colors.white;
    final Color textColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Colors.black;
    final Color cardColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF2A2A2A) 
        : Colors.white;
    final Color secondaryTextColor = cardColor == Colors.white ? Colors.grey[600]! : Colors.grey[400]!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Barra de arrastre
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: secondaryTextColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Título
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Términos de Servicio',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Línea divisoria
              Divider(color: secondaryTextColor.withOpacity(0.2)),
              
              // Contenido principal (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fecha de actualización
                      Text(
                        'Última actualización: 5 de abril de 2025',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 1: Introducción
                      Text(
                        '1. Introducción',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bienvenido a nuestra aplicación. Estos Términos de Servicio ("Términos") rigen tu acceso y uso de nuestra aplicación, incluyendo cualquier contenido, funcionalidad y servicios ofrecidos a través de la aplicación.\n\nAl registrarte, acceder o utilizar nuestra aplicación, aceptas estar legalmente vinculado por estos Términos. Si no estás de acuerdo con alguno de estos términos, no debes acceder ni utilizar la aplicación.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 2: Uso de la Aplicación
                      Text(
                        '2. Uso de la Aplicación',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '2.1 Elegibilidad\nDebes tener al menos 18 años de edad para utilizar nuestra aplicación. Al utilizar la aplicación, confirmas que cumples con este requisito de edad.\n\n2.2 Registro de Cuenta\nPara acceder a ciertas funciones de la aplicación, debes crear una cuenta. Eres responsable de mantener la confidencialidad de tu información de cuenta y contraseña.\n\n2.3 Uso Prohibido\nTe comprometes a no utilizar la aplicación para fines ilegales o prohibidos por estos Términos. No debes intentar obtener acceso no autorizado a nuestros sistemas o redes.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 3: Propiedad Intelectual
                      Text(
                        '3. Propiedad Intelectual',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'La aplicación y su contenido original, características y funcionalidad son propiedad de nuestra empresa y están protegidos por leyes internacionales de derechos de autor, marcas registradas, patentes y otros derechos de propiedad intelectual o derechos de propiedad.\n\nNo puedes reproducir, distribuir, modificar, crear obras derivadas, exhibir públicamente, ejecutar públicamente, republicar, descargar, almacenar o transmitir cualquier material de nuestra aplicación, excepto según lo permitido por estos Términos.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 4: Limitación de Responsabilidad
                      Text(
                        '4. Limitación de Responsabilidad',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'En ningún caso seremos responsables por daños indirectos, incidentales, especiales, consecuentes o punitivos, incluyendo pérdida de beneficios, datos, uso, buena voluntad u otras pérdidas intangibles, resultantes de tu acceso o uso o incapacidad para acceder o usar la aplicación.\n\nNuestra responsabilidad total hacia ti por cualquier reclamación relacionada con estos Términos o la aplicación no excederá la cantidad que hayas pagado a la aplicación durante los últimos 12 meses.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 5: Modificaciones
                      Text(
                        '5. Modificaciones',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nos reservamos el derecho, a nuestra sola discreción, de modificar o reemplazar estos Términos en cualquier momento. Si una revisión es material, proporcionaremos al menos 30 días de aviso antes de que los nuevos términos entren en vigencia. Lo que constituye un cambio material será determinado a nuestra sola discreción.\n\nAl continuar accediendo o utilizando nuestra aplicación después de que esas revisiones entren en vigencia, aceptas estar sujeto a los términos revisados.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 6: Contacto
                      Text(
                        '6. Contacto',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Si tienes alguna pregunta sobre estos Términos, por favor contáctanos en terms@medicalapp.com.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Botón de cerrar
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Entendido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
