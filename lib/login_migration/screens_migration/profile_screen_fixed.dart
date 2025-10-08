import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:mi_app_flutter/login_medical/screens_medical/settings_screen.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/settings_screen.dart';

// import 'package:mi_app_flutter/login_medical/screens_medical/home.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/home.dart';

import 'package:provider/provider.dart';
// import 'package:mi_app_flutter/login_medical/login_screen.dart';
import 'package:mi_app_flutter/login_migration/login_screen.dart';

import 'package:mi_app_flutter/providers/theme_provider.dart';
// import 'package:mi_app_flutter/login_medical/perfil_screen.dart';
import 'package:mi_app_flutter/login_migration/perfil_screen.dart';

import 'package:mi_app_flutter/servicios/perfil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  String nombreUsuario = '';
  String telefono = '';
  String email = '';
  String direccion = '';
  String fechaNacimiento = '';
  String imagenUrl = '';
  String codigoReferido = '';
  ImageProvider? _imagenLocal;
  final picker = ImagePicker();
  File? _imagen;
  final PerfilServicio _perfilServicio = PerfilServicio();

  Future<Map<String, dynamic>?> obtenerDatosUsuario() async {
    try {
      final perfilServicio = PerfilServicio();
      return await perfilServicio.obtenerPerfilUsuario();
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  void _cargarDatosUsuario() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Primero intentar obtener datos del servicio de perfil
      final perfilData = await _perfilServicio.obtenerPerfilUsuario();
      
      // Luego obtener datos de SharedPreferences (que pueden haber sido actualizados por otras pantallas)
      final prefs = await SharedPreferences.getInstance();
      final nombreGuardado = prefs.getString('nombre_usuario');
      final imagenGuardada = prefs.getString('imagen_url');
      
      if (perfilData != null) {
        setState(() {
          // Usar datos del perfil para la informaciÃ³n detallada
          nombreUsuario = perfilData['nombre'] ?? nombreGuardado ?? 'Usuario';
          telefono = perfilData['telefono'] != null && perfilData['telefono'].toString().isNotEmpty
              ? perfilData['telefono']
              : 'Sin telÃ©fono';
          email = perfilData['email'] ?? 'Sin email';
          direccion = perfilData['direccion'] ?? 'Sin direcciÃ³n';
          codigoReferido = perfilData['codigo_referido'] ?? '';
          
          // Para la imagen, priorizar la de SharedPreferences si existe (mÃ¡s reciente)
          imagenUrl = imagenGuardada?.isNotEmpty == true ? imagenGuardada : (perfilData['imagen_url'] ?? '');

          // Guardar datos actualizados en SharedPreferences para otras pantallas
          prefs.setString('nombre_usuario', nombreUsuario);
          prefs.setString('imagen_url', imagenUrl);
          
          print("âœ… Datos de usuario cargados en Profile: $nombreUsuario");

          // Verificar si hay una imagen local guardada
          _verificarImagenLocal();

          if (perfilData['fecha_nacimiento'] != null &&
              perfilData['fecha_nacimiento'].toString().isNotEmpty) {
            try {
              final fecha = DateTime.parse(perfilData['fecha_nacimiento']);
              fechaNacimiento = DateFormat('dd/MM/yyyy').format(fecha);
            } catch (e) {
              print('Error al parsear la fecha: $e');
              fechaNacimiento = 'No disponible';
            }
          }
        });
      } else if (nombreGuardado != null) {
        // Si no hay datos del perfil pero sÃ­ de SharedPreferences
        setState(() {
          nombreUsuario = nombreGuardado;
          imagenUrl = imagenGuardada ?? '';
          print("âœ… Usando datos guardados en Profile: $nombreUsuario");
        });
        
        // Verificar si hay una imagen local guardada
        _verificarImagenLocal();
      }
    } catch (e) {
      print('Error al cargar datos del perfil: $e');
      setState(() {
        nombreUsuario = 'Usuario';
        telefono = 'Sin telÃ©fono';
        email = 'Sin email';
        direccion = 'Sin direcciÃ³n';
        fechaNacimiento = 'No disponible';
        imagenUrl = '';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  Future<void> _verificarImagenLocal() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Primero intentar obtener la imagen mÃ¡s reciente de la base de datos
      final userData = await obtenerDatosUsuario();
      if (userData != null && userData['imagen_url'] != null && userData['imagen_url'].toString().isNotEmpty) {
        final imagenBD = userData['imagen_url'].toString();
        setState(() {
          imagenUrl = imagenBD;
          print("âœ… Imagen actualizada desde la base de datos: $imagenUrl");
        });
        // Guardar la imagen de la BD en SharedPreferences para sincronizar con otras pantallas
        await prefs.setString('imagen_url', imagenUrl);
        return;
      }
      
      // Si no hay imagen en la BD, verificar si hay una imagen guardada en SharedPreferences
      final imagenUrlGuardada = prefs.getString('imagen_url');
      if (imagenUrlGuardada != null && imagenUrlGuardada.isNotEmpty && imagenUrlGuardada != imagenUrl) {
        setState(() {
          imagenUrl = imagenUrlGuardada;
          print("âœ… Sincronizando imagen desde SharedPreferences en Profile: $imagenUrl");
        });
        return;
      }
      
      // Si no hay imagen URL del servidor ni en SharedPreferences, intentar usar la imagen local
      if (imagenUrl.isEmpty) {
        final imagenLocalPath = prefs.getString('imagen_local_path');
      
        if (imagenLocalPath != null) {
          final file = File(imagenLocalPath);
          if (await file.exists()) {
            setState(() {
              // Usar la ruta local como URL
              imagenUrl = 'file://$imagenLocalPath';
              // Guardar para sincronizar con otras pantallas
              prefs.setString('imagen_url', imagenUrl);
              print("âœ… Usando imagen local en Profile: $imagenUrl");
            });
          }
        }
      } else {
        // Si tenemos una imagen URL, guardarla para sincronizar con otras pantallas
        prefs.setString('imagen_url', imagenUrl);
      }
    } catch (e) {
      print("âŒ Error al verificar imagen local: $e");
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cerrar SesiÃ³n',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkModeEnabled ? Colors.white : const Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Â¿EstÃ¡s seguro de cerrar sesiÃ³n?',
                style: TextStyle(
                  fontSize: 14,
                  color: darkModeEnabled ? Colors.white : const Color(0xFF6E7191),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF4485FD),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 200, 16, 16),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SÃ­, Salir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required String title,
    dynamic icon,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    return Column(
      children: [
        ListTile(
          leading: icon is IconData
              ? Icon(
                  icon,
                  color: const Color(0xFF4485FD),
                  size: 22,
                )
              : icon,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: darkModeEnabled ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            color: darkModeEnabled ? Colors.grey[800] : Colors.grey[200],
            height: 1,
            indent: 24,
            endIndent: 24,
          ),
      ],
    );
  }

  void _showHelpAndSupportModal(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    // Definir colores segÃºn el tema
    final backgroundColor = darkModeEnabled ? const Color(0xFF121212) : Colors.white;
    final textColor = darkModeEnabled ? Colors.white : const Color(0xFF2D3142);
    final secondaryTextColor = darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB);
    final handleBarColor = darkModeEnabled ? Colors.grey[700] : Colors.grey[300];
    final primaryColor = const Color(0xFF4485FD);
    final primaryColorLight = primaryColor.withOpacity(0.1);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: handleBarColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: darkModeEnabled ? primaryColor.withOpacity(0.2) : primaryColorLight,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.support_agent,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ayuda y Soporte',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Â¿CÃ³mo podemos ayudarte hoy?',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: textColor),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Acciones rÃ¡pidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildQuickActionCard(
                        icon: Icons.chat_outlined,
                        title: 'Chat en vivo',
                        subtitle: 'Habla con nuestro equipo de soporte',
                        color: primaryColor,
                        isDarkMode: darkModeEnabled,
                        onTap: () {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('FunciÃ³n de chat no disponible en este momento'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        icon: Icons.call_outlined,
                        title: 'Llamar',
                        subtitle: 'Hablar con un agente',
                        color: const Color(0xFF00CC9F),
                        isDarkMode: darkModeEnabled,
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        icon: Icons.email_outlined,
                        title: 'Correo electrÃ³nico',
                        subtitle: 'Obtener soporte por correo electrÃ³nico',
                        color: const Color(0xFFFD9344),
                        isDarkMode: darkModeEnabled,
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        icon: Icons.forum_outlined,
                        title: 'Comunidad',
                        subtitle: 'Unirse a nuestros foros',
                        color: const Color(0xFFAC5CD9),
                        isDarkMode: darkModeEnabled,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Preguntas Frecuentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildFaqItem(
                        question: 'Â¿CÃ³mo puedo agendar una cita?',
                        answer: 'Para agendar una cita, navega a la secciÃ³n de CategorÃ­as, selecciona tu especialidad mÃ©dica, elige una fecha y hora, y confirma tu cita.',
                      ),
                      _buildFaqItem(
                        question: 'Â¿CÃ³mo puedo reprogramar mi cita?',
                        answer: 'Puedes reprogramar tu cita visitando tu lista de citas, seleccionando la cita que deseas cambiar, y eligiendo la opciÃ³n "Reprogramar".',
                      ),
                      _buildFaqItem(
                        question: 'Â¿QuÃ© mÃ©todos de pago son aceptados?',
                        answer: 'Aceptamos tarjetas de crÃ©dito/dÃ©bito, PayPal, y cobertura de seguros donde sea aplicable. Puedes gestionar tus mÃ©todos de pago en la configuraciÃ³n de la cuenta.',
                      ),
                      _buildFaqItem(
                        question: 'Â¿CÃ³mo puedo actualizar mi informaciÃ³n mÃ©dica?',
                        answer: 'Puedes actualizar tu informaciÃ³n mÃ©dica visitando tu perfil, seleccionando "Editar Perfil", y actualizando las secciones relevantes de la historia mÃ©dica.',
                      ),
                      _buildFaqItem(
                        question: 'Â¿Mi informaciÃ³n mÃ©dica es segura?',
                        answer: 'SÃ­, usamos protocolos de seguridad estÃ¡ndar de industria para garantizar que tus datos mÃ©dicos permanezcan privados y seguros en todo momento.',
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(left: 4, right: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : const Color(0xFF2D3142),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF9BA0AB),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkModeEnabled ? Colors.white : const Color(0xFF2D3142),
          ),
        ),
        iconColor: const Color(0xFF4485FD),
        collapsedIconColor: darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: darkModeEnabled ? Colors.grey[300] : const Color(0xFF2D3142),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditionsModal(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    // Definir colores segÃºn el tema
    final backgroundColor = darkModeEnabled ? const Color(0xFF121212) : Colors.white;
    final textColor = darkModeEnabled ? Colors.white : const Color(0xFF2D3142);
    final secondaryTextColor = darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB);
    final handleBarColor = darkModeEnabled ? Colors.grey[700] : Colors.grey[300];
    final primaryColor = const Color(0xFF4485FD);
    final primaryColorLight = primaryColor.withOpacity(0.1);
    final tabBackgroundColor = darkModeEnabled ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA);
    final selectedTabColor = darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white;
    final selectedTabTextColor = primaryColor;
    final unselectedTabTextColor = darkModeEnabled 
        ? Colors.grey[400] 
        : const Color(0xFF2D3142).withOpacity(0.5);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: handleBarColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: darkModeEnabled ? primaryColor.withOpacity(0.2) : primaryColorLight,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.gavel_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TÃ©rminos y Condiciones',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ãšltima actualizaciÃ³n: 28 de marzo de 2025',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: textColor),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: tabBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedTabColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'VersiÃ³n actual',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: selectedTabTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Versiones anteriores',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: unselectedTabTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildTermsSection(
                        title: 'IntroducciÃ³n',
                        content: 'Bienvenido a MedApp ("nosotros", "nuestro", o "nos"). Estos TÃ©rminos y Condiciones rigen su uso de nuestra aplicaciÃ³n mÃ³vil (la "AplicaciÃ³n") y los servicios ofrecidos a travÃ©s de la AplicaciÃ³n (colectivamente, los "Servicios"). Al acceder o utilizar nuestros Servicios, usted acepta estar sujeto a estos TÃ©rminos y Condiciones.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'AceptaciÃ³n de los TÃ©rminos',
                        content: 'Al descargar, instalar o utilizar nuestra AplicaciÃ³n, usted reconoce que ha leÃ­do, comprendido y aceptado estar sujeto a estos TÃ©rminos y Condiciones. Si no acepta estos tÃ©rminos, por favor, no utilice nuestros Servicios.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'Elegibilidad',
                        content: 'Usted debe tener al menos 18 aÃ±os de edad para utilizar nuestros Servicios. Al utilizar nuestros Servicios, usted declara y garantiza que tiene al menos 18 aÃ±os de edad y que tiene la capacidad legal para celebrar un acuerdo vinculante.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'Privacidad',
                        content: 'Su privacidad es importante para nosotros. Nuestra PolÃ­tica de Privacidad explica cÃ³mo recopilamos, utilizamos y protegemos su informaciÃ³n personal cuando utiliza nuestros Servicios. Al utilizar nuestros Servicios, usted acepta la recopilaciÃ³n, uso y divulgaciÃ³n de informaciÃ³n como se describe en nuestra PolÃ­tica de Privacidad.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'Licencia',
                        content: 'Sujeto a estos TÃ©rminos y Condiciones, le otorgamos una licencia limitada, no exclusiva, no transferible y revocable para descargar, instalar y utilizar la AplicaciÃ³n para su uso personal y no comercial.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'Restricciones',
                        content: 'Usted acepta no: (a) licenciar, vender, arrendar, asignar, distribuir, transmitir, alojar, subcontratar, divulgar o explotar comercialmente la AplicaciÃ³n; (b) modificar, realizar trabajos derivados, desensamblar, descifrar, realizar compilaciÃ³n inversa o ingenierÃ­a inversa de cualquier parte de la AplicaciÃ³n; (c) acceder a la AplicaciÃ³n para construir un sitio web, producto o servicio similar o competitivo; o (d) copiar, reproducir, distribuir, republicar, descargar, mostrar, publicar o transmitir cualquier parte de la AplicaciÃ³n en cualquier forma o por cualquier medio.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'Modificaciones',
                        content: 'Reservamos el derecho de modificar estos TÃ©rminos y Condiciones en cualquier momento. Nos pondremos en contacto con usted de cualquier cambio material publicando los nuevos TÃ©rminos y Condiciones en la AplicaciÃ³n. Su uso continuo de nuestros Servicios despuÃ©s de tales modificaciones constituye su aceptaciÃ³n de los tÃ©rminos modificados.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'TerminaciÃ³n',
                        content: 'Podemos terminar o suspender su acceso a nuestros Servicios inmediatamente, sin previo aviso o responsabilidad, por cualquier razÃ³n, incluyendo pero no limitado a un incumplimiento de estos TÃ©rminos y Condiciones.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'Ley Aplicable',
                        content: 'Estos TÃ©rminos y Condiciones se regirÃ¡n y se interpretarÃ¡n de conformidad con las leyes del territorio en el que operamos, sin considerar sus disposiciones de conflicto de leyes.',
                        isDarkMode: darkModeEnabled,
                      ),
                      _buildTermsSection(
                        title: 'Contacto',
                        content: 'Si tiene alguna pregunta sobre estos TÃ©rminos y Condiciones, pÃ³ngase en contacto con nosotros en support@medapp.com.',
                        isDarkMode: darkModeEnabled,
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection({
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : const Color(0xFF9BA0AB);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarImagenLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagenLocalPath = prefs.getString('imagen_local_path');
      
      if (imagenLocalPath != null) {
        final file = File(imagenLocalPath);
        if (await file.exists()) {
          setState(() {
            _imagenLocal = FileImage(file);
            print("Imagen local cargada desde: $imagenLocalPath");
          });
        }
      }
    } catch (e) {
      print("Error al cargar imagen local: $e");
    }
  }

  // MÃ©todo para seleccionar una imagen desde la galerÃ­a
  Future<void> _seleccionarImagen() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // CompresiÃ³n para reducir el tamaÃ±o del archivo
        maxWidth: 600,    // Limitar el ancho mÃ¡ximo
        maxHeight: 600,   // Limitar el alto mÃ¡ximo
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // Verificar que el archivo existe y tiene tamaÃ±o
        if (await imageFile.exists()) {
          final fileSize = await imageFile.length();
          print("Imagen seleccionada: ${pickedFile.path}");
          print("TamaÃ±o de la imagen: $fileSize bytes");
          print("Tipo de archivo: ${pickedFile.name.split('.').last}");
          
          // Guardar la ruta de la imagen en SharedPreferences para uso temporal
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('imagen_local_temp', imageFile.path);
          await prefs.setString('imagen_local_path', imageFile.path);
          
          // Actualizar el perfil con la nueva imagen
          _actualizarImagenPerfil(imageFile);
        } else {
          print("Error: El archivo de imagen no existe");
        }
      } else {
        print("SelecciÃ³n de imagen cancelada por el usuario");
      }
    } catch (e) {
      print("Error al seleccionar la imagen: $e");
    }
  }
  
  // MÃ©todo para actualizar la imagen de perfil
  Future<void> _actualizarImagenPerfil(File imagen) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Obtener los datos del usuario para mantener los valores actuales
      final userData = await obtenerDatosUsuario();
      if (userData != null) {
        // Convertir la fecha al formato correcto (YYYY-MM-DD)
        String fechaFormateada = fechaNacimiento;
        if (fechaNacimiento.isNotEmpty && fechaNacimiento != 'No disponible') {
          try {
            // Parsear la fecha del formato DD/MM/YYYY
            final partes = fechaNacimiento.split('/');
            if (partes.length == 3) {
              fechaFormateada = "${partes[2]}-${partes[1]}-${partes[0]}";
            }
          } catch (e) {
            print("Error al formatear la fecha: $e");
            // Si hay error, intentar obtener la fecha original
            fechaFormateada = userData['fecha_nacimiento'] ?? '';
          }
        }
        
        print("Enviando fecha en formato: $fechaFormateada");
        
        final resultado = await _perfilServicio.actualizarPerfil(
          nombre: nombreUsuario,
          email: email,
          telefono: telefono,
          direccion: direccion,
          fecha_nacimiento: fechaFormateada,
          imagen: imagen,
        );
        
        if (resultado != null) {
          print("Perfil actualizado exitosamente con nueva imagen");
          
          // Guardar la imagen local para uso futuro
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('perfil_actualizado', true);
          
          // Guardar la ruta de la imagen local para sincronizaciÃ³n entre pantallas
          await prefs.setString('imagen_local_path', imagen.path);
          
          // Actualizar la URL de la imagen para sincronizaciÃ³n
          final imagenUrlNueva = 'file://${imagen.path}';
          await prefs.setString('imagen_url', imagenUrlNueva);
          
          // Actualizar nombre de usuario para sincronizaciÃ³n
          await prefs.setString('nombre_usuario', nombreUsuario);
          
          print("âœ… Imagen actualizada y sincronizada: $imagenUrlNueva");
          
          // Recargar los datos del usuario
          _cargarDatosUsuario();
          
          // Actualizar la imagen local
          setState(() {
            _imagenLocal = FileImage(imagen);
            _imagen = imagen;
            imagenUrl = imagenUrlNueva;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imagen de perfil actualizada correctamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          print("Error al actualizar la imagen de perfil");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar la imagen de perfil'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("Error al actualizar la imagen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarImagenLocal();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: themeProvider.darkModeEnabled ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: themeProvider.darkModeEnabled ? const Color(0xFF121212) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios, 
              color: themeProvider.darkModeEnabled ? Colors.white : Colors.black87
            ),
            onPressed: () {
              _navigateToHome();
            },
          ),
          title: Text(
            'Mi Perfil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: themeProvider.darkModeEnabled ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          centerTitle: true,
        ),
        body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: DecorationImage(
                            image: imagenUrl.isNotEmpty
                              ? imagenUrl.startsWith('file://')
                                ? FileImage(File(imagenUrl.replaceFirst('file://', '')))
                                : NetworkImage(
                                    imagenUrl.startsWith('http') 
                                      ? imagenUrl 
                                      : "https://inmigracion.maval.tech/storage/$imagenUrl"
                                  )
                              : _imagenLocal ?? const AssetImage('assets/doctor.webp') as ImageProvider,
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              print('Error loading profile image: $exception');
                              // Si hay un error al cargar la imagen, intentar usar la imagen local
                              if (_imagenLocal != null) {
                                setState(() {
                                  imagenUrl = '';  // Limpiar la URL para que use la imagen local
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _seleccionarImagen,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A80F0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
               const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 380,
                        child: Text(
                          nombreUsuario,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center, // centra el texto dentro del SizedBox
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.darkModeEnabled
                                ? Colors.white
                                : const Color(0xFF2D3142),
                          ),
                        ),
                      ),
                    ),

                const SizedBox(height: 4),
                Text(
                  telefono,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB),
                  ),
                ),
                const SizedBox(height: 32),
                _buildProfileItem(
                  title: 'Editar Perfil',
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditarPerfilScreen(),
                      ),
                    );
                  },
                ),

                _buildProfileItem(
                  title: 'ConfiguraciÃ³n',
                  icon: Icons.settings_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                _buildProfileItem(
                  title: 'Ayuda y Soporte',
                  icon: Icons.help_outline,
                  onTap: () {
                    _showHelpAndSupportModal(context);
                  },
                ),
                _buildProfileItem(
                  title: 'TÃ©rminos y Condiciones',
                  icon: Icons.security_outlined,
                  onTap: () {
                    _showTermsAndConditionsModal(context);
                  },
                ),
                ListTile(
                  leading: Image.asset(
                    'assets/icons/logout.png',
                    width: 22,
                    height: 22,
                    color: Colors.red,
                  ),
                  title: Text(
                    'Cerrar SesiÃ³n',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: themeProvider.darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () async {
                    final shouldLogout = await _showLogoutDialog(context);
                    if (shouldLogout == true) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
                
                // Espacio para separar la secciÃ³n de cÃ³digo de referido
                const SizedBox(height: 40),
                
                // SecciÃ³n de cÃ³digo de referido
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CÃ³digo de referido
                      Text(
                        'CÃ³digo de referido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4CAF50), // Color verde para el tÃ­tulo
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            codigoReferido.isNotEmpty ? codigoReferido : '12345678',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700), // Color amarillo para el cÃ³digo
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () async {
                              // Obtener el cÃ³digo de referido
                              final code = codigoReferido.isNotEmpty ? codigoReferido : '12345678';
                              
                              // FunciÃ³n para copiar el cÃ³digo al portapapeles con manejo de errores
                              try {
                                await Clipboard.setData(ClipboardData(text: code));
                                
                                // Mostrar mensaje de Ã©xito
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('CÃ³digo copiado al portapapeles: $code'),
                                    backgroundColor: const Color(0xFF4CAF50),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                // Mostrar mensaje de error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error al copiar el cÃ³digo. IntÃ©ntalo de nuevo.'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy,
                                color: Colors.blue,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // NÃºmero de referidos
                      Text(
                        'NÃºmero de referidos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: themeProvider.darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: obtenerDatosUsuario(),
                        builder: (context, snapshot) {
                          String numeroReferidos = '0';
                          if (snapshot.hasData && snapshot.data != null) {
                            numeroReferidos = snapshot.data!['numero_referido'] ?? '0';
                          }
                          return Text(
                            numeroReferidos,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4485FD), // Color azul para el nÃºmero
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
