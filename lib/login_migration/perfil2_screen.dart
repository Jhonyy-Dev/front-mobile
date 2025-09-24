import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/profile_screen.dart';

class EditarPerfilScreen extends StatefulWidget {
  final bool iniciarEnModoEdicion;
  
  const EditarPerfilScreen({super.key, this.iniciarEnModoEdicion = false});

  @override
  _EditarPerfilScreenState createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  File? _imagen;
  final picker = ImagePicker();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  DateTime? _fechaNacimiento;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.iniciarEnModoEdicion;
    // Simulación de datos pre-cargados
    _nombreController.text = "María González";
    _telefonoController.text = "+52 555 123 4567";
    _emailController.text = "maria.gonzalez@ejemplo.com";
    _fechaNacimiento = DateTime(1990, 5, 15);
    _direccionController.text = "Av. Reforma 123, CDMX";
  }

  void GuardarDatos(){
    
    print("Datos guardados:$_imagen , ${_nombreController.text}, ${_telefonoController.text}, ${_emailController.text}, ${_direccionController.text}, ${_fechaNacimiento.toString()}");


  }

  Future<void> _seleccionarImagen() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagen = File(pickedFile.path);
      });
    }
  }

  Future<void> _seleccionarFechaNacimiento(BuildContext context, bool isDarkMode) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF4A80F0),
              onPrimary: Colors.white,
              surface: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              onSurface: isDarkMode ? Colors.white : const Color(0xFF2D3142),
            ), dialogTheme: DialogThemeData(backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaNacimiento = fechaSeleccionada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.darkModeEnabled;
    final formatoFecha = DateFormat('dd/MM/yyyy');
    
    // Colores adaptados al tema
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = const Color(0xFF4A80F0);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);
    final subtitleColor = isDarkMode ? Colors.white70 : const Color(0xFF9BA0AB);
    final dividerColor = isDarkMode ? Colors.white24 : Colors.black12;
    
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(
        color: _isEditing ? primaryColor : subtitleColor,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: subtitleColor),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con imagen de perfil
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          backgroundImage: _imagen != null ? FileImage(_imagen!) : null,
                          child: _imagen == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: primaryColor,
                                )
                              : null,
                        ),
                      ),
                      // Botón de editar foto
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _seleccionarImagen,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Nombre del usuario
                  Text(
                    _nombreController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Correo electrónico
                  Text(
                    _emailController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botón de guardar centrado
                  if (_isEditing)
                    ElevatedButton.icon(
                      onPressed: () {
                         GuardarDatos();
                      },
                      icon: Icon(Icons.save_rounded),
                      label: Text(
                        'Guardar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                ],
              ),
            ),
            
            // Tarjeta de información personal
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.3) 
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la sección
                    Text(
                      'Información Personal',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Nombre completo
                    Text(
                      'Nombre completo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isEditing
                        ? TextField(
                            controller: _nombreController,
                            style: TextStyle(color: textColor),
                            decoration: inputDecoration.copyWith(
                              labelText: 'Nombre completo',
                            ),
                          )
                        : Text(
                            _nombreController.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                    const SizedBox(height: 16),
                    Divider(color: dividerColor),
                    const SizedBox(height: 16),
                    
                    // Teléfono
                    Text(
                      'Teléfono',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isEditing
                        ? TextField(
                            controller: _telefonoController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: textColor),
                            decoration: inputDecoration.copyWith(
                              labelText: 'Teléfono',
                            ),
                          )
                        : Text(
                            _telefonoController.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                    const SizedBox(height: 16),
                    Divider(color: dividerColor),
                    const SizedBox(height: 16),
                    
                    // Correo electrónico
                    Text(
                      'Correo electrónico',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isEditing
                        ? TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: textColor),
                            decoration: inputDecoration.copyWith(
                              labelText: 'Correo electrónico',
                            ),
                          )
                        : Text(
                            _emailController.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                    const SizedBox(height: 16),
                    Divider(color: dividerColor),
                    const SizedBox(height: 16),
                    
                    // Fecha de nacimiento
                    Text(
                      'Fecha de nacimiento',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isEditing
                        ? GestureDetector(
                            onTap: () => _seleccionarFechaNacimiento(context, isDarkMode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fechaNacimiento != null
                                        ? formatoFecha.format(_fechaNacimiento!)
                                        : 'Selecciona una fecha',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Text(
                            _fechaNacimiento != null
                                ? formatoFecha.format(_fechaNacimiento!)
                                : 'No especificada',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                    const SizedBox(height: 16),
                    Divider(color: dividerColor),
                    const SizedBox(height: 16),
                    
                    // Dirección
                    Text(
                      'Dirección',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isEditing
                        ? TextField(
                            controller: _direccionController,
                            style: TextStyle(color: textColor),
                            decoration: inputDecoration.copyWith(
                              labelText: 'Dirección',
                            ),
                          )
                        : Text(
                            _direccionController.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}