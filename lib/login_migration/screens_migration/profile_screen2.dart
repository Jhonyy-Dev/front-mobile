import 'package:flutter/material.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/home.dart';
import 'package:mi_app_flutter/login_migration/login_screen.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/settings_screen.dart';
import 'package:mi_app_flutter/login_migration/perfil_screen.dart';

// import 'package:mi_app_flutter/servicios/login_servicio.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  String nombreUsuario = '';
  String telefono = "";

  
  void cargarUsuarioDatos() async {
    // AuthService authService = AuthService();
    final userData = await obtenerDatosUsuario();

    if (userData != null) {
      setState(() {
        nombreUsuario = userData['usuario']['nombre'];
        telefono =userData['usuario']['telefono'];
      });
    }
  }

   @override
   void initState() {
     super.initState();
     cargarUsuarioDatos();
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
    final bool isDarkMode = themeProvider.darkModeEnabled;
    
    final Color dialogBgColor = isDarkMode ? Color(0xFF242526) : Colors.white;
    final Color primaryTextColor = isDarkMode ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = isDarkMode ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: dialogBgColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Estás seguro de cerrar sesión?',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
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
                        'Cancel',
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
                        'Salir',

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    final Color textColor = darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color iconColor = Color(0xFF4485FD);
    final Color arrowColor = darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    final Color dividerColor = darkModeEnabled ? Color(0xFF3A3B3C) : Color(0xFFE5E5E5);
    
    return Column(
      children: [
        ListTile(
          tileColor: darkModeEnabled ? Color(0xFF242526) : Colors.white,
          leading: icon is IconData
              ? Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                )
              : Image.asset(icon, width: 22, height: 22, color: iconColor),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: arrowColor,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            color: dividerColor,
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
    
    final Color backgroundColor = darkModeEnabled ? Color(0xFF121212) : Colors.white;
    final Color primaryTextColor = darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    final Color handleBarColor = darkModeEnabled ? Colors.grey.shade700 : Colors.grey.shade300;
    
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                          color: const Color(0xFF4485FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: Color(0xFF4485FD),
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
                                color: primaryTextColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '¿Cómo podemos ayudarte hoy?',
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
                        icon: Icon(Icons.close, color: primaryTextColor),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
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
                        subtitle: 'Converse con nuestro equipo de soporte',
                        color: const Color(0xFF4485FD),
                        onTap: () {
                          Navigator.pop(context); // Close the modal first
                        },
                      ),
                      _buildQuickActionCard(
                        icon: Icons.call_outlined,
                        title: 'Llamar',
                        subtitle: 'Habla con un agente',
                        color: const Color(0xFF00CC9F),
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        icon: Icons.email_outlined,
                        title: 'Correo electrónico',
                        subtitle: 'Obtén soporte por correo electrónico',
                        color: const Color(0xFFFD9344),
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        icon: Icons.forum_outlined,
                        title: 'Comunidad',
                        subtitle: 'Únete a nuestros foros',
                        color: const Color(0xFFAC5CD9),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Preguntas Frecuentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildFaqItem(
                        question: '¿Cómo programo una cita?',
                        answer: 'Para programar una cita, navega a la sección de Categorías, selecciona tu especialidad médica, elige una fecha y hora, y confirma tu cita.',
                      ),
                      _buildFaqItem(
                        question: '¿Cómo puedo reprogramar mi cita?',
                        answer: 'Puedes reprogramar tu cita visitando la lista de citas, seleccionando la cita que quieres cambiar, y eligiendo la opción "Reprogramar".',
                      ),
                      _buildFaqItem(
                        question: '¿Qué métodos de pago son aceptados?',
                        answer: 'Aceptamos tarjetas de crédito/débito, PayPal, y cobertura de seguros donde sea aplicable. Puedes gestionar tus métodos de pago en tus ajustes de cuenta.',
                      ),
                      _buildFaqItem(
                        question: '¿Cómo puedo actualizar mi información médica?',
                        answer: 'Puedes actualizar tu información médica visitando tu perfil, seleccionando "Editar Perfil", y actualizando las secciones relevantes de tu historial médico.',
                      ),
                      _buildFaqItem(
                        question: '¿Mi información médica es segura?',
                        answer: 'Sí, usamos protocolos de seguridad estándar del industria para garantizar que tus datos médicos permanezcan privados y seguros en todo momento.',
                      ),
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
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    final Color cardBgColor = darkModeEnabled ? Color(0xFF242526) : Colors.white;
    final Color primaryTextColor = darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(left: 4, right: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(darkModeEnabled ? 0.3 : 0.05),
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
                color: primaryTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
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
    
    final Color cardBgColor = darkModeEnabled ? Color(0xFF242526) : Colors.white;
    final Color primaryTextColor = darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(darkModeEnabled ? 0.3 : 0.04),
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
            color: primaryTextColor,
          ),
        ),
        iconColor: const Color(0xFF4485FD),
        collapsedIconColor: darkModeEnabled ? const Color(0xFFB0B3B8) : const Color(0xFF9BA0AB),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
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
    
    final Color backgroundColor = darkModeEnabled ? Color(0xFF121212) : Colors.white;
    final Color primaryTextColor = darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    final Color cardBgColor = darkModeEnabled ? Color(0xFF242526) : Colors.white;
    final Color handleBarColor = darkModeEnabled ? Colors.grey.shade700 : Colors.grey.shade300;
    final Color tabBgColor = darkModeEnabled ? Color(0xFF242526) : Color(0xFFF5F7FA);
    
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                          color: const Color(0xFF4485FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: Color(0xFF4485FD),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terms and Conditions',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Last updated: March 28, 2025',
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
                        icon: Icon(Icons.close, color: primaryTextColor),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: tabBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(darkModeEnabled ? 0.3 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Current version',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4485FD),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Previous versions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
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
                        title: '1. Introducción',
                        content: 'Bienvenido a MigrationApp ("nosotros", "nuestro" o "nos"). Estos Términos y Condiciones rigen el uso que usted hace de nuestra aplicación móvil (la "Aplicación") y los servicios ofrecidos a través de la Aplicación (colectivamente, los "Servicios"). Al acceder o utilizar nuestros Servicios, usted acepta estar sujeto a estos Términos y Condiciones.',
                      ),
                      _buildTermsSection(
                        title: '2. Aceptación de Términos',
                        content: 'Al descargar, instalar o utilizar nuestra Aplicación, usted reconoce que ha leído, comprendido y aceptado estar sujeto a estos Términos y Condiciones. Si no acepta estos términos, no utilice nuestros Servicios.',
                      ),
                      _buildTermsSection(
                        title: '3. Desclamación Legal',
                        content: 'La información proporcionada a través de nuestros Servicios es meramente informativa y no está destinada a ser asesoramiento legal. La Aplicación no es un sustituto del asesoramiento legal, diagnóstico o tratamiento profesional. Siempre busque el consejo de su abogado o otro proveedor de servicios legales calificados con cualquier pregunta que tenga sobre su situación migratoria o situación legal.',
                      ),
                      _buildTermsSection(
                        title: '4. Cuentas de Usuario',
                        content: 'Para utilizar ciertas características de nuestros Servicios, puede necesitar crear una cuenta. Usted es responsable de mantener el confidencialidad de sus credenciales de cuenta y por todas las actividades que ocurren bajo su cuenta. Usted se compromete a proporcionar información precisa y completa cuando cree su cuenta y actualizar su información para mantenerla precisa y actual.',
                      ),
                      _buildTermsSection(
                        title: '5. Política de Privacidad',
                        content: 'Su privacidad es importante para nosotros. Nuestra Política de Privacidad explica cómo recopilamos, usamos y protegemos su información personal. Al utilizar nuestros Servicios, usted consiente la recopilación y uso de su información tal como se describe en nuestra Política de Privacidad.',
                      ),
                      _buildTermsSection(
                        title: '6. Reservas de Citas',
                        content: 'Nuestra Aplicación le permite reservar citas con proveedores legales. Aunque nos esforzamos por garantizar la exactitud de la información del proveedor y la disponibilidad, no podemos garantizar que toda la información sea completa o actual. Es su responsabilidad confirmar los detalles de la cita directamente con el proveedor legal.',
                      ),
                      _buildTermsSection(
                        title: '7. Conducta del Usuario',
                        content: 'Usted se compromete a no utilizar nuestros Servicios para:\n• Violar cualquier ley o regulación\n• infringir los derechos de los demás\n• presentar información falsa o engañosa\n• interferir con el funcionamiento correcto de la Aplicación\n• intentar obtener acceso no autorizado a nuestros sistemas o cuentas de usuario',
                      ),
                      _buildTermsSection(
                        title: '8. Propiedad Intelectual',
                        content: 'Todos los contenidos, características y funcionalidades de nuestra Aplicación, incluyendo pero no limitado a texto, gráficos, logotipos, iconos, imágenes, sonidos, y software, son propiedad de nosotros o nuestros licenciantes y están protegidos por derechos de autor, marcas registradas y otros derechos de propiedad intelectual.',
                      ),
                      _buildTermsSection(
                        title: '9. Limitación de Responsabilidad',
                        content: 'A la medida que lo permita la ley, no seremos responsables por daños indirectos, incidentales, especiales, consecuentes, o castigarios, incluyendo pero no limitado a pérdidas de ganancias, datos, o uso, que surjan de o en conexión con su uso de nuestros Servicios.',
                      ),
                      _buildTermsSection(
                        title: '10. Modificaciones a los Términos',
                        content: 'Reservamos el derecho de modificar estos Términos y Condiciones en cualquier momento. Nos comunicaremos con usted de cualquier cambio material publicando los nuevos Términos y Condiciones en la Aplicación. Su uso continuo de nuestros Servicios después de tales modificaciones constituye su aceptación de los términos modificados.',
                      ),
                      _buildTermsSection(
                        title: '11. Terminación',
                        content: 'Podemos terminar o suspender su acceso a nuestros Servicios inmediatamente, sin aviso previo o responsabilidad, por cualquier razón, incluyendo pero no limitado a un incumplimiento de estos Términos y Condiciones.',
                      ),
                      _buildTermsSection(
                        title: '12. Ley Regulatoria',
                        content: 'Estos Términos y Condiciones serán gobernados y interpretados en conformidad con las leyes del territorio en el que operamos, sin considerar sus disposiciones de conflictos de ley.',
                      ),
                      _buildTermsSection(
                        title: '13. Contacto',
                        content: 'Si tiene alguna pregunta sobre estos Términos y Condiciones, por favor, contáctenos en support@migrationapp.com.',
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4485FD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'I Accept',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    final Color primaryTextColor = darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    final Color backgroundColor = darkModeEnabled ? Color(0xFF121212) : Colors.white;
    final Color primaryTextColor = darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    
    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF4485FD)),
            onPressed: _navigateToHome,
          ),
          title: Text(
            'Perfil',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
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
                      image: const DecorationImage(
                        image: AssetImage('assets/doctor.webp'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4485FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              nombreUsuario,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              telefono,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
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
                    builder: (context) => const EditarPerfilScreen(iniciarEnModoEdicion: true),
                  ),
                );
              },
            ),
            _buildProfileItem(
              title: 'Configuración',
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
              title: 'Términos y Condiciones',
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
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: secondaryTextColor,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () async {
                final shouldLogout = await _showLogoutDialog(context);
                if (shouldLogout == true) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}