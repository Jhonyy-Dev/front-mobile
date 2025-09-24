import 'package:flutter/material.dart';
import 'package:mi_app_flutter/login_migration/login_screen.dart';
// import 'package:mi_app_flutter/servicios/login_servicio.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  final String _selectedTextSize = 'Medium';
  final String _selectedLanguage = 'English';
  final String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    // Inicializar el estado del modo oscuro desde el provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _darkModeEnabled = themeProvider.darkModeEnabled;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Define dynamic colors based on dark mode state
    final Color backgroundColor = _darkModeEnabled ? Color(0xFF121212) : Colors.white;
    final Color primaryTextColor = _darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    final Color iconBgColor = _darkModeEnabled ? Color(0xFF3A3B3C) : Colors.blue.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF4485FD)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuración',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              Text(
                'Cuenta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              SizedBox(height: 16),
              _buildSettingItem(
                icon: Icons.person,
                iconBackground: iconBgColor,
                title: 'Información Personal',
                showArrow: true,
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.lock,
                iconBackground: iconBgColor,
                title: 'Cambiar Contraseña',
                showArrow: true,
                onTap: () {
                  _showChangePasswordModal(context);
                },
              ),
              
              SizedBox(height: 24),
              
              // Notifications Section
              Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              SizedBox(height: 16),
              _buildSettingItem(
                icon: Icons.notifications,
                iconBackground: iconBgColor,
                title: 'Notificaciones',
                subtitle: 'Recibe notificaciones sobre citas y actualizaciones',
                trailing: Switch(
                  value: _pushNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _pushNotificationsEnabled = value;
                    });
                  },
                  activeColor: Color(0xFF4485FD),
                ),
                onTap: () {},
              ),
              
              SizedBox(height: 24),
              
              // Appearance Section
              Text(
                'Apariencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              SizedBox(height: 16),
              _buildSettingItem(
                icon: Icons.dark_mode,
                iconBackground: iconBgColor,
                title: 'Modo Oscuro',
                subtitle: 'Switch between light and dark themes',
                trailing: Switch(
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    // Actualizar el provider cuando cambie el switch
                    themeProvider.toggleDarkMode(value);
                  },
                  activeColor: Color(0xFF4485FD),
                ),
                onTap: () {},
              ),
              
              SizedBox(height: 24),
              
              // Security Section
              Text(
                'Seguridad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              SizedBox(height: 16),
              _buildSettingItem(
                icon: Icons.fingerprint,
                iconBackground: iconBgColor,
                title: 'Autenticación Biométrica',
                subtitle: 'Usa la huella digital o reconocimiento facial para iniciar sesión',
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: (value) {
                    setState(() {
                      _biometricEnabled = value;
                    });
                  },
                  activeColor: Color(0xFF4485FD),
                ),
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.privacy_tip,
                iconBackground: iconBgColor,
                title: 'Política de Privacidad',
                showArrow: true,
                onTap: () {
                  _showPrivacyPolicyModal(context);
                },
              ),
              _buildSettingItem(
                icon: Icons.description,
                iconBackground: iconBgColor,
                title: 'Terms & Conditions',
                showArrow: true,
                onTap: () {
                  _showTermsAndConditionsModal(context);
                },
              ),
              
              SizedBox(height: 24),
              
              // About Section
              Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              SizedBox(height: 16),
              _buildSettingItem(
                icon: Icons.info,
                iconBackground: iconBgColor,
                title: 'App Version',
                trailing: Text(
                  _appVersion,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.help_outline,
                iconBackground: iconBgColor,
                title: 'Help & Support',
                showArrow: true,
                onTap: () {
                  _showHelpAndSupportModal(context);
                },
              ),
              
              SizedBox(height: 40),
              
              // Log Out Button
              Center(
                child: TextButton(
                  onPressed: () async {
                    final shouldLogout = await _showLogoutDialog(context);
                    if (shouldLogout == true) {
                      // AuthService authService = AuthService();
                      await cerrarSesion();
                      
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  child: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '¿Estás seguro de cerrar sesión?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9BA0AB),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF4485FD),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 200, 16, 16),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
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

  // Help and Support Modal
  void _showHelpAndSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        // Prevent modal from closing when tapping inside
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: _darkModeEnabled ? Color(0xFF121212) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                // Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF4485FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.support_agent,
                          color: Color(0xFF4485FD),
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ayuda y Soporte',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '¿Cómo podemos ayudarte hoy?',
                              style: TextStyle(
                                fontSize: 14,
                                color: _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142)),
                      ),
                    ],
                  ),
                ),
                
                // Quick actions
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Quick action cards
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildQuickActionCard(
                        icon: Icons.chat_outlined,
                        title: 'Chat en vivo',
                        subtitle: 'Converse con nuestro equipo de soporte',
                        color: Color(0xFF4485FD),
                        onTap: () {
                          Navigator.pop(context); // Close the modal first
                        },
                      ),
                      _buildQuickActionCard(
                        icon: Icons.call_outlined,
                        title: 'Llamar',
                        subtitle: 'Habla con un agente',
                        color: Color(0xFF00CC9F),
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        icon: Icons.email_outlined,
                        title: 'Correo electrónico',
                        subtitle: 'Obtén soporte por correo electrónico',
                        color: Color(0xFFFD9344),
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        icon: Icons.forum_outlined,
                        title: 'Comunidad',
                        subtitle: 'Únete a nuestros foros',
                        color: Color(0xFFAC5CD9),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // FAQs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Preguntas Frecuentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // FAQ items
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.symmetric(horizontal: 20),
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

  // Terms and Conditions Modal
  void _showTermsAndConditionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        // Prevent modal from closing when tapping inside
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: _darkModeEnabled ? Color(0xFF121212) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                // Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF4485FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.gavel_rounded,
                          color: Color(0xFF4485FD),
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Términos y Condiciones',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Última actualización: 28 de marzo, 2025',
                              style: TextStyle(
                                fontSize: 14,
                                color: _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142)),
                      ),
                    ],
                  ),
                ),
                
                // Version tabs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _darkModeEnabled ? Color(0xFF242526) : Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _darkModeEnabled ? Color(0xFF121212) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Versión actual',
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
                              'Versiones anteriores',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF2D3142).withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Terms content
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.symmetric(horizontal: 20),
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
                      SizedBox(height: 30),
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

  Future<void> _showPrivacyPolicyModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _darkModeEnabled ? Color(0xFF121212) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _darkModeEnabled ? Color(0xFF242526) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.privacy_tip,
                            color: Color(0xFF4485FD),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Política de Privacidad',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.all(20),
                      children: [
                        _buildTermsSection(
                          title: 'Introducción',
                          content: 'Esta Política de Privacidad describe cómo recopilamos, usamos y divulgamos su información personal cuando utiliza nuestra aplicación de citas médicas. Estamos comprometidos a proteger su privacidad y garantizar la seguridad de su información personal.',
                        ),
                        _buildTermsSection(
                          title: 'Información que Recopilamos',
                          content: 'Recopilamos información personal que proporcionas directamente a nosotros, como tu nombre, dirección de correo electrónico, número de teléfono, fecha de nacimiento y historial médico. También recopilamos información sobre tu dispositivo y cómo utilizas nuestra aplicación, incluyendo dirección IP, tipo de navegador y sistema operativo.',
                        ),
                        _buildTermsSection(
                          title: 'Uso de tu Información',
                          content: 'Usamos tu información personal para proporcionar y mejorar nuestros servicios, procesar tus citas, comunicarnos contigo y cumplir con obligaciones legales. También podemos usar tu información para personalizar tu experiencia y enviarle materiales promocionales sobre nuestros servicios.',
                        ),
                        _buildTermsSection(
                          title: 'Compartir Información',
                          content: 'Podemos compartir tu información personal con proveedores de atención médica para facilitar tus citas. También podemos compartir tu información con terceros que desempeñan servicios por nuestra cuenta, como procesamiento de pagos y análisis de datos.',
                        ),
                        _buildTermsSection(
                          title: 'Seguridad de los Datos',
                          content: 'Implementamos medidas de seguridad apropiadas para proteger tu información personal de acceso no autorizado, alteración, divulgación o destrucción. Usamos cifrado, servidores seguros y evaluaciones de seguridad regulares para proteger tus datos.',
                        ),
                        _buildTermsSection(
                          title: 'Tus Derechos',
                          content: 'Tienes el derecho de acceder, corregir, actualizar o eliminar tu información personal. También puedes oponerte al procesamiento de tu información personal o solicitar una restricción en su uso. Para ejercer estos derechos, por favor contactanos usando la información proporcionada abajo.',
                        ),
                        _buildTermsSection(
                          title: 'Cambio en esta Política',
                          content: 'Podemos actualizar esta Política de Privacidad en cualquier momento para reflejar cambios en nuestras prácticas o requisitos legales. Nos comunicaremos con usted de cualquier cambio material publicando la política actualizada en nuestra aplicación y actualizando la fecha "Última Actualización".',
                        ),
                        _buildTermsSection(
                          title: 'Contacto',
                          content: 'Si tiene alguna pregunta o preocupación sobre esta Política de Privacidad o nuestras prácticas de privacidad, por favor, contáctenos en privacy@medicalapp.com o llamenos al +1-800-123-4567.',
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Última Actualización: April 4, 2025',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB),
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isLoading = false;
    
    // Validación de campos
    bool isCurrentPasswordValid = false;
    bool isNewPasswordValid = false;
    bool isConfirmPasswordValid = false;
    bool passwordsMatch = false;
    
    // Colores según el tema
    final Color backgroundColor = _darkModeEnabled ? Color(0xFF242526) : Colors.white;
    final Color primaryTextColor = _darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    final Color inputBgColor = _darkModeEnabled ? Color(0xFF3A3B3C) : Colors.grey.shade50;
    final Color borderColor = _darkModeEnabled ? Color(0xFF4E4F50) : Colors.grey.shade200;
    final Color accentColor = Color(0xFF4485FD);
    final Color errorColor = Color(0xFFE53935);
    final Color successColor = Color(0xFF43A047);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // Validar contraseña actual
            void validateCurrentPassword(String value) {
              setState(() {
                isCurrentPasswordValid = value.length >= 6;
              });
            }
            
            // Validar nueva contraseña
            void validateNewPassword(String value) {
              setState(() {
                isNewPasswordValid = value.length >= 8 && 
                                    RegExp(r'[A-Z]').hasMatch(value) && 
                                    RegExp(r'[0-9]').hasMatch(value);
                
                // Verificar si las contraseñas coinciden
                if (confirmPasswordController.text.isNotEmpty) {
                  passwordsMatch = newPasswordController.text == confirmPasswordController.text;
                  isConfirmPasswordValid = passwordsMatch;
                }
              });
            }
            
            // Validar confirmación de contraseña
            void validateConfirmPassword(String value) {
              setState(() {
                passwordsMatch = value == newPasswordController.text;
                isConfirmPasswordValid = value.isNotEmpty && passwordsMatch;
              });
            }
            
            // Verificar si el formulario es válido
            bool isFormValid() {
              return isCurrentPasswordValid && isNewPasswordValid && isConfirmPasswordValid && passwordsMatch;
            }
            
            // Manejar el cambio de contraseña
            Future<void> handleChangePassword() async {
              if (!isFormValid()) return;
              
              setState(() {
                isLoading = true;
              });
              
              // Simulación de proceso de cambio de contraseña
              await Future.delayed(Duration(seconds: 2));
              
              // Aquí iría la lógica real para cambiar la contraseña
              // LoginServicio.cambiarContrasena(
              //   currentPasswordController.text,
              //   newPasswordController.text
              // );
              
              setState(() {
                isLoading = false;
              });
              
              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '¡Contraseña actualizada con éxito!',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: successColor,
                  duration: Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              
              // Cerrar el modal
              Navigator.pop(context);
            }
            
            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de arrastre y espacio superior
                    SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _darkModeEnabled ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Encabezado con botón de cierre (X)
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          // Contenido del encabezado
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.lock_reset,
                                  color: accentColor,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cambiar Contraseña',
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Actualiza tu contraseña para mayor seguridad',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Botón de cierre (X)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _darkModeEnabled ? Color(0xFF3A3B3C) : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: _darkModeEnabled ? Colors.white : Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Línea divisoria
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(
                        color: _darkModeEnabled ? Colors.grey[800] : Colors.grey[200],
                        thickness: 1,
                      ),
                    ),
                    
                    // Formulario
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contraseña actual
                            Text(
                              'Contraseña Actual',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrentPasswordValid 
                                    ? (currentPasswordController.text.isEmpty ? borderColor : successColor)
                                    : (currentPasswordController.text.isEmpty ? borderColor : errorColor),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: currentPasswordController,
                                obscureText: obscureCurrentPassword,
                                style: TextStyle(color: primaryTextColor),
                                onChanged: validateCurrentPassword,
                                decoration: InputDecoration(
                                  hintText: 'Ingresa tu contraseña actual',
                                  hintStyle: TextStyle(color: secondaryTextColor),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                                      color: secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureCurrentPassword = !obscureCurrentPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (currentPasswordController.text.isNotEmpty && !isCurrentPasswordValid)
                              Padding(
                                padding: EdgeInsets.only(top: 8, left: 8),
                                child: Text(
                                  'La contraseña debe tener al menos 6 caracteres',
                                  style: TextStyle(
                                    color: errorColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            
                            SizedBox(height: 24),
                            
                            // Nueva contraseña
                            Text(
                              'Nueva Contraseña',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isNewPasswordValid 
                                    ? (newPasswordController.text.isEmpty ? borderColor : successColor)
                                    : (newPasswordController.text.isEmpty ? borderColor : errorColor),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: newPasswordController,
                                obscureText: obscureNewPassword,
                                style: TextStyle(color: primaryTextColor),
                                onChanged: validateNewPassword,
                                decoration: InputDecoration(
                                  hintText: 'Crea una nueva contraseña',
                                  hintStyle: TextStyle(color: secondaryTextColor),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                      color: secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureNewPassword = !obscureNewPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (newPasswordController.text.isNotEmpty && !isNewPasswordValid)
                              Padding(
                                padding: EdgeInsets.only(top: 8, left: 8),
                                child: Text(
                                  'La contraseña debe tener al menos 8 caracteres, una mayúscula y un número',
                                  style: TextStyle(
                                    color: errorColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            
                            // Indicadores de seguridad
                            if (newPasswordController.text.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Requisitos de seguridad:',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    _buildPasswordRequirement(
                                      'Al menos 8 caracteres',
                                      newPasswordController.text.length >= 8,
                                      primaryTextColor,
                                    ),
                                    SizedBox(height: 4),
                                    _buildPasswordRequirement(
                                      'Al menos una letra mayúscula',
                                      RegExp(r'[A-Z]').hasMatch(newPasswordController.text),
                                      primaryTextColor,
                                    ),
                                    SizedBox(height: 4),
                                    _buildPasswordRequirement(
                                      'Al menos un número',
                                      RegExp(r'[0-9]').hasMatch(newPasswordController.text),
                                      primaryTextColor,
                                    ),
                                  ],
                                ),
                              ),
                            
                            SizedBox(height: 24),
                            
                            // Confirmar contraseña
                            Text(
                              'Confirmar Contraseña',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isConfirmPasswordValid 
                                    ? (confirmPasswordController.text.isEmpty ? borderColor : successColor)
                                    : (confirmPasswordController.text.isEmpty ? borderColor : errorColor),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: confirmPasswordController,
                                obscureText: obscureConfirmPassword,
                                style: TextStyle(color: primaryTextColor),
                                onChanged: validateConfirmPassword,
                                decoration: InputDecoration(
                                  hintText: 'Confirma tu nueva contraseña',
                                  hintStyle: TextStyle(color: secondaryTextColor),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                      color: secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureConfirmPassword = !obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (confirmPasswordController.text.isNotEmpty && !passwordsMatch)
                              Padding(
                                padding: EdgeInsets.only(top: 8, left: 8),
                                child: Text(
                                  'Las contraseñas no coinciden',
                                  style: TextStyle(
                                    color: errorColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            
                            SizedBox(height: 40),
                            
                            // Botón de actualizar
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isFormValid() && !isLoading ? handleChangePassword : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4485FD),
                                  disabledBackgroundColor: _darkModeEnabled 
                                    ? Colors.grey[700] 
                                    : Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Actualizar Contraseña',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Botón de cancelar
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: EdgeInsets.only(left: 4, right: 4),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _darkModeEnabled ? Color(0xFF242526) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
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
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB),
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
    // Define colors based on dark mode
    final Color cardBgColor = _darkModeEnabled ? Color(0xFF242526) : Colors.white;
    final Color primaryTextColor = _darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_darkModeEnabled ? 0.3 : 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        iconColor: Color(0xFF4485FD),
        collapsedIconColor: _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB),
        childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
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

  Widget _buildTermsSection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkModeEnabled ? Colors.white : Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconBackground,
    required String title,
    String? subtitle,
    bool showArrow = false,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    // Define colors based on dark mode
    final Color cardBgColor = _darkModeEnabled ? Color(0xFF242526) : Colors.white;
    final Color primaryTextColor = _darkModeEnabled ? Colors.white : Color(0xFF2D3142);
    final Color secondaryTextColor = _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_darkModeEnabled ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Color(0xFF4485FD),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: primaryTextColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              )
            : null,
        trailing: trailing ??
            (showArrow
                ? Icon(
                    Icons.chevron_right,
                    color: _darkModeEnabled ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB),
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildPasswordRequirement(String text, bool isMet, Color textColor) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          color: isMet ? Color(0xFF43A047) : Colors.grey,
          size: 16,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
