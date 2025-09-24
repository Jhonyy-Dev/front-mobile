import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:mi_app_flutter/servicios/actualizar_contra.dart';
import 'package:mi_app_flutter/login_medical/perfil_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state variables
  bool notificationsEnabled = true;
  bool biometricsEnabled = false;
  String selectedLanguage = 'Español';
  List<String> availableLanguages = ['Español', 'English', 'Français'];
  double textSize = 1.0;

  @override
  Widget build(BuildContext context) {
    // Obtener el ThemeProvider para acceder al estado del modo oscuro
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    // Definir colores según el estado del switch Dark Mode
    final Color primaryColor = const Color(0xFF4485FD);

    // Aplicar colores según el estado del switch darkModeEnabled
    final Color textColor = darkModeEnabled ? Colors.white : const Color(0xFF2D3142);
    final Color subtitleColor = darkModeEnabled ? Colors.grey[400]! : const Color(0xFF6E7191);
    final Color backgroundColor = darkModeEnabled ? const Color(0xFF121212) : Colors.white;
    final Color cardColor = darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuración',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: const Color.fromARGB(35, 0, 0, 0).withOpacity(0.1),
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cuenta', textColor),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  title: 'Información Personal',
                  icon: Icons.person,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: subtitleColor,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditarPerfilScreen(),
                      ),
                    );
                  },
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
                _buildSettingsItem(
                  title: 'Cambiar Contraseña',
                  icon: Icons.lock_outline,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: subtitleColor,
                  ),
                  onTap: () {
                    _showChangePasswordModal(context, textColor, backgroundColor, cardColor);
                  },
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
              ],
              cardColor: cardColor,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Notificaciones', textColor),
            _buildSettingsCard(
              children: [
                _buildSwitchSettingsItem(
                  title: 'Notificaciones',
                  subtitle: 'Recibe notificaciones sobre citas y actualizaciones',
                  icon: Icons.notifications_none,
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  primaryColor: primaryColor,
                ),
              ],
              cardColor: cardColor,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Apariencia', textColor),
            _buildSettingsCard(
              children: [
                _buildSwitchSettingsItem(
                  title: 'Modo Oscuro',
                  subtitle: 'Tema claro y oscuro',
                  icon: Icons.dark_mode_outlined,
                  value: darkModeEnabled,
                  onChanged: (value) {
                    themeProvider.toggleDarkMode(value);
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  primaryColor: primaryColor,
                ),
              ],
              cardColor: cardColor,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Seguridad', textColor),
            _buildSettingsCard(
              children: [
                _buildSwitchSettingsItem(
                  title: 'Autenticación Biométrica',
                  subtitle: 'Usa tu huella o reconocimiento facial para iniciar sesión',
                  icon: Icons.fingerprint,
                  value: biometricsEnabled,
                  onChanged: (value) {
                    setState(() {
                      biometricsEnabled = value;
                    });
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  primaryColor: primaryColor,
                ),
                _buildSettingsItem(
                  title: 'Configuración de Privacidad',
                  icon: Icons.privacy_tip_outlined,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: subtitleColor,
                  ),
                  onTap: () {
                    _showPrivacySettingsModal(context, textColor, backgroundColor, cardColor);
                  },
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
              ],
              cardColor: cardColor,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Acerca de', textColor),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  title: 'Versión de la Aplicación',
                  icon: Icons.info_outline,
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  onTap: () {},
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
                _buildSettingsItem(
                  title: 'Términos de Servicio',
                  icon: Icons.description_outlined,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: subtitleColor,
                  ),
                  onTap: () {
                    _showTermsOfServiceModal(context, textColor, backgroundColor, cardColor);
                  },
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
                _buildSettingsItem(
                  title: 'Política de Privacidad',
                  icon: Icons.policy_outlined,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: subtitleColor,
                  ),
                  onTap: () {
                    _showPrivacyPolicyModal(context, textColor, backgroundColor, cardColor);
                  },
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
              ],
              cardColor: cardColor,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children, required Color cardColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required IconData icon,
    required Widget trailing,
    required VoidCallback onTap,
    required Color textColor,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  // Método para mostrar el modal de cambio de contraseña
  void _showChangePasswordModal(BuildContext context, Color textColor, Color backgroundColor, Color cardColor) {
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
    final Color primaryColor = const Color(0xFF4485FD);
    final Color inputBgColor = cardColor;
    final Color borderColor = cardColor == Colors.white ? Colors.grey[300]! : Colors.grey[800]!;
    final Color secondaryTextColor = cardColor == Colors.white ? Colors.grey[600]! : Colors.grey[400]!;
    final Color errorColor = const Color(0xFFE53935);
    final Color successColor = const Color(0xFF43A047);
    
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
                isCurrentPasswordValid = value.length >= 8;
              });
            }
            
            // Validar nueva contraseña
            void validateNewPassword(String value) {
              setState(() {
                isNewPasswordValid = value.length >= 8;
                
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

              final servicio = ActualizarContraServicio();
              final resultado = await servicio.actualizarContra(
                currentPasswordController.text,
                newPasswordController.text,
                confirmPasswordController.text,
              );

              print(resultado); 

              setState(() {
                isLoading = false;
              });

              if (resultado == null) {
                // ?%xito
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

                Navigator.pop(context); // Cierra modal
            } else {
                // Mostrar alerta cuando la contraseña es incorrecta
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        'Contraseña no válida',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      content: Text(
                        resultado,
                        style: TextStyle(fontSize: 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Entendido',
                            style: TextStyle(
                              color: Color(0xFF4485FD),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
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
                          color: cardColor == Colors.white ? Colors.grey[300] : Colors.grey[700],
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
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.lock_reset,
                                  color: primaryColor,
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
                                        color: textColor,
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
                                  color: cardColor == Colors.white ? Colors.grey.shade200 : Color(0xFF3A3B3C),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: cardColor == Colors.white ? Colors.black87 : Colors.white,
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
                        color: cardColor == Colors.white ? Colors.grey[200] : Colors.grey[800],
                        thickness: 1,
                      ),
                    ),
                    
                    // Formulario
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contraseña actual
                            Text(
                              'Contraseña Actual',
                              style: TextStyle(
                                color: textColor,
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
                                style: TextStyle(color: textColor),
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
                                  'La contraseña debe tener al menos 8 caracteres',
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
                                color: textColor,
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
                                style: TextStyle(color: textColor),
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
                                  'La contraseña debe tener al menos 8 caracteres',
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
                                      textColor,
                                    ),
                                   
                                  ],
                                ),
                              ),
                            
                            SizedBox(height: 24),
                            
                            // Confirmar contraseña
                            Text(
                              'Confirmar Contraseña',
                              style: TextStyle(
                                color: textColor,
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
                                style: TextStyle(color: textColor),
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
                                  disabledBackgroundColor: cardColor == Colors.white ? Colors.grey[300] : Colors.grey[700],
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

  // Método para construir los requisitos de contraseña
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

  // Método para mostrar el modal de Configuración de Privacidad
  void _showPrivacySettingsModal(BuildContext context, Color textColor, Color backgroundColor, Color cardColor) {
    // Definir variables para los switches
    bool locationEnabled = true;
    bool analyticsEnabled = true;
    bool personalizationEnabled = true;
    
    // Colores según el tema
    final Color primaryColor = const Color(0xFF4485FD);
    final Color secondaryTextColor = cardColor == Colors.white ? Colors.grey[600]! : Colors.grey[400]!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,  // Agregar esta línea
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          Icons.privacy_tip,
                          color: primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Configuración de Privacidad',
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
                          // Descripción general
                          Text(
                            'Gestiona cómo se utiliza tu información personal dentro de la aplicación. Estos ajustes afectan a tu experiencia y a los datos que compartimos con terceros.',
                            style: TextStyle(
                              color: textColor.withOpacity(0.8),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Sección de ubicación
                          Text(
                            'Servicios de ubicación',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Compartir ubicación',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Permite que la aplicación acceda a tu ubicación para servicios personalizados',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                            value: locationEnabled,
                            activeColor: primaryColor,
                            onChanged: (value) {
                              setState(() {
                                locationEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Sección de análisis
                          Text(
                            'Análisis y mejoras',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Compartir datos de uso',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Ayúdanos a mejorar enviando datos anónimos sobre el uso de la aplicación',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                            value: analyticsEnabled,
                            activeColor: primaryColor,
                            onChanged: (value) {
                              setState(() {
                                analyticsEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Sección de personalización
                          Text(
                            'Personalización',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Contenido personalizado',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Recibe recomendaciones basadas en tu actividad y preferencias',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                            value: personalizationEnabled,
                            activeColor: primaryColor,
                            onChanged: (value) {
                              setState(() {
                                personalizationEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Nota informativa
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Puedes cambiar estas preferencias en cualquier momento. Para más información, consulta nuestra Política de Privacidad.',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.8),
                                      fontSize: 14,
                                      height: 1.5,
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
                  
                  // Botones de acción
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Guardar configuración y cerrar
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Guardar',
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Método para mostrar el modal de Términos de Servicio
  void _showTermsOfServiceModal(BuildContext context, Color textColor, Color backgroundColor, Color cardColor) {
    // Colores según el tema
    final Color primaryColor = const Color(0xFF4485FD);
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
                        '2.1 Elegibilidad\nDebes tener al menos 18 años de edad para utilizar nuestra aplicación. Al utilizar la aplicación, confirmas que cumples con este requisito de edad.\n\n2.2 Registro de Cuenta\nPara acceder a ciertas funciones de la aplicación, debes crear una cuenta. Eres responsable de mantener la confidencialidad de tu información de cuenta y contraseña.\n\n2.3 Uso Prohibido\nTe comprometes a no utilizar la aplicación para fines ilegales o prohibidos por estos Términos. No debes intentar obtener acceso no autorizado a ninguna parte de la aplicación, a otros sistemas o redes conectadas a la aplicación.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 3: Contenido
                      Text(
                        '3. Contenido y Propiedad Intelectual',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '3.1 Propiedad del Contenido\nTodos los derechos de propiedad intelectual en la aplicación y su contenido (excluyendo el contenido proporcionado por los usuarios) son propiedad de nuestra empresa o de nuestros licenciantes.\n\n3.2 Licencia Limitada\nSe te otorga una licencia limitada, no exclusiva y no transferible para acceder y utilizar la aplicación para tu uso personal y no comercial.',
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
                        'En la medida permitida por la ley aplicable, nuestra empresa no será responsable por daños indirectos, incidentales, especiales, consecuentes o punitivos, o cualquier pérdida de beneficios o ingresos, ya sea incurrida directa o indirectamente, o cualquier pérdida de datos, uso, buena voluntad, u otras pérdidas intangibles.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 5: Modificaciones
                      Text(
                        '5. Modificaciones de los Términos',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nos reservamos el derecho de modificar estos Términos en cualquier momento. Si realizamos cambios materiales, te notificaremos a través de la aplicación o por correo electrónico. Tu uso continuado de la aplicación después de dichos cambios constituye tu aceptación de los nuevos Términos.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botón de aceptar
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para mostrar el modal de Política de Privacidad
  void _showPrivacyPolicyModal(BuildContext context, Color textColor, Color backgroundColor, Color cardColor) {
    // Colores según el tema
    final Color primaryColor = const Color(0xFF4485FD);
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
                      Icons.policy,
                      color: primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Política de Privacidad',
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
                      
                      // Introducción
                      Text(
                        'Valoramos tu privacidad y nos comprometemos a proteger tus datos personales. Esta Política de Privacidad describe cómo recopilamos, utilizamos y compartimos tu información cuando utilizas nuestra aplicación.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 1: Información que recopilamos
                      Text(
                        '1. Información que Recopilamos',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1.1 Información que nos proporcionas\n• Información de registro: nombre, dirección de correo electrónico, contraseña.\n• Información de perfil: foto, datos demográficos, preferencias.\n• Comunicaciones: mensajes que envías a través de la aplicación.\n\n1.2 Información recopilada automáticamente\n• Datos de uso: interacciones con la aplicación, páginas visitadas, tiempo de uso.\n• Información del dispositivo: tipo de dispositivo, sistema operativo, identificadores únicos.\n• Datos de ubicación: con tu consentimiento, podemos recopilar datos de ubicación precisos o aproximados.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 2: Cómo utilizamos la información
                      Text(
                        '2. Cómo Utilizamos tu Información',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Utilizamos la información recopilada para:\n• Proporcionar, mantener y mejorar nuestra aplicación.\n• Personalizar tu experiencia y ofrecerte contenido relevante.\n• Comunicarnos contigo, incluyendo notificaciones sobre actualizaciones o cambios.\n• Analizar tendencias de uso y optimizar nuestros servicios.\n• Detectar, prevenir y abordar problemas técnicos o de seguridad.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 3: Compartir información
                      Text(
                        '3. Compartir tu Información',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Podemos compartir tu información personal en las siguientes circunstancias:\n• Con proveedores de servicios que nos ayudan a operar la aplicación.\n• Para cumplir con obligaciones legales o responder a solicitudes legales.\n• Para proteger nuestros derechos, privacidad, seguridad o propiedad.\n• En relación con una fusión, venta de activos o financiación.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 4: Tus derechos
                      Text(
                        '4. Tus Derechos y Opciones',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Dependiendo de tu ubicación, puedes tener ciertos derechos con respecto a tus datos personales, incluyendo:\n• Acceder a tus datos personales.\n• Corregir datos inexactos.\n• Eliminar tus datos personales.\n• Oponerte al procesamiento de tus datos.\n• Retirar tu consentimiento en cualquier momento.\n\nPuedes ejercer estos derechos a través de la configuración de la aplicación o contactándonos directamente.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 5: Seguridad
                      Text(
                        '5. Seguridad de los Datos',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Implementamos medidas de seguridad técnicas y organizativas para proteger tus datos personales contra el acceso no autorizado, la pérdida o la alteración. Sin embargo, ningún sistema es completamente seguro, y no podemos garantizar la seguridad absoluta de tu información.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección 6: Cambios
                      Text(
                        '6. Cambios a esta Política',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Podemos actualizar esta Política de Privacidad periódicamente. Te notificaremos sobre cambios significativos publicando la nueva política en la aplicación o enviándote una notificación.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botón de aceptar
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
