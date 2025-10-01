import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/profile_screen.dart';
import 'package:mi_app_flutter/servicios/perfil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditarPerfilScreen extends StatefulWidget {
  final bool iniciarEnModoEdicion;
  
  const EditarPerfilScreen({super.key, this.iniciarEnModoEdicion = true});

  @override
  _EditarPerfilScreenState createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {

   
  final PerfilServicio userServicio = PerfilServicio();
    

  File? _imagen;
  ImageProvider? _imagenExistente;
  final picker = ImagePicker();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  DateTime? _fechaNacimiento;
  late bool _isEditing;
  
  String _codigoReferido = "";
  String _numeroReferido = "0";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = false; // Siempre iniciar en modo visualización
    _cargarDatosPerfil();
    _cargarImagenLocal();
  }

  Future<void> _cargarDatosPerfil() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await userServicio.obtenerPerfilUsuario();

    if (userData != null) {
      print(userData);

      setState(() {
        _nombreController.text = userData['nombre'] ?? '';
        _telefonoController.text = userData['telefono'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _direccionController.text = userData['direccion'] ?? '';
        _codigoReferido = userData['codigo_referido'] ?? '';
        _numeroReferido = userData['numero_referido'] ?? '0';
        

        // Formatear fecha de nacimiento si existe
        if (userData['fecha_nacimiento'] != null && 
            userData['fecha_nacimiento'].toString().isNotEmpty) {
          try {
            _fechaNacimiento = DateTime.parse(userData['fecha_nacimiento']);
          } catch (e) {
            print('Error al parsear la fecha: $e');
            _fechaNacimiento = null;
          }
        }
      });
    }
  } catch (e) {
    print('Error al cargar datos del perfil: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _cargarImagenLocal() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Primero intentar obtener la imagen desde SharedPreferences (sincronizada con otras pantallas)
    final imagenUrl = prefs.getString('imagen_url');
    if (imagenUrl != null && imagenUrl.isNotEmpty) {
      if (imagenUrl.startsWith('file://')) {
        // Si es una imagen de archivo local
        final filePath = imagenUrl.replaceFirst('file://', '');
        final file = File(filePath);
        if (await file.exists()) {
          setState(() {
            _imagenExistente = FileImage(file);
            _imagen = file;
            print("✅ Imagen sincronizada en EditarPerfil desde SharedPreferences: $imagenUrl");
          });
        } else {
          print("⚠️ Archivo no encontrado: $filePath, intentando usar imagen_local_path");
          _intentarCargarDesdeImagenLocalPath(prefs);
        }
      } else if (imagenUrl.startsWith('http')) {
        // Si es una imagen de red
        setState(() {
          _imagenExistente = NetworkImage(imagenUrl);
          print("✅ Imagen de red sincronizada en EditarPerfil: $imagenUrl");
        });
      } else if (imagenUrl.isNotEmpty) {
        // Si es una ruta relativa del servidor
        setState(() {
          _imagenExistente = NetworkImage("https://api-inmigracion.maval.tech/storage/usuarios/$imagenUrl");
          print("✅ Imagen del servidor sincronizada en EditarPerfil: $imagenUrl");
        });
      }
      return;
    }
    
    // Si no hay imagen URL en SharedPreferences, intentar usar la imagen local
    _intentarCargarDesdeImagenLocalPath(prefs);
  } catch (e) {
    print("❌ Error al cargar imagen local en EditarPerfil: $e");
  }
}
  
  // Método auxiliar para cargar la imagen desde imagen_local_path
  Future<void> _intentarCargarDesdeImagenLocalPath(SharedPreferences prefs) async {
    final imagenLocalPath = prefs.getString('imagen_local_path');
    if (imagenLocalPath != null) {
      final file = File(imagenLocalPath);
      if (await file.exists()) {
        setState(() {
          _imagenExistente = FileImage(file);
          _imagen = file;
          // Guardar también en imagen_url para sincronizar con otras pantallas
          final urlImagen = 'file://$imagenLocalPath';
          prefs.setString('imagen_url', urlImagen);
          print("✅ Imagen local cargada en EditarPerfil desde: $imagenLocalPath");
          print("✅ Sincronizada en SharedPreferences como: $urlImagen");
        });
      }
    }
  }
  
  // Método para obtener el ImageProvider correcto según el tipo de imagen
  ImageProvider _getImageProvider() {
    // Si hay una imagen seleccionada, usarla primero
    if (_imagen != null) {
      return FileImage(_imagen!);
    }
    
    // Si hay una imagen existente, usarla
    if (_imagenExistente != null) {
      return _imagenExistente!;
    }
    
    // Verificar si hay una URL de imagen en SharedPreferences
    try {
      final prefs = SharedPreferences.getInstance();
      prefs.then((prefs) {
        final imagenUrl = prefs.getString('imagen_url');
        if (imagenUrl != null && imagenUrl.isNotEmpty) {
          _cargarImagenLocal(); // Cargar la imagen de SharedPreferences
        }
      });
    } catch (e) {
      print("Error al verificar imagen en SharedPreferences: $e");
    }
    
    // Si no hay imagen, usar la imagen por defecto
    return const AssetImage('assets/doctor.webp');
  }

  Future<void> _guardarCambios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_imagen != null) {
        print("Imagen seleccionada para subir: ${_imagen!.path}");
        print("Tamaño de la imagen: ${await _imagen!.length()} bytes");
        
        // Verificar que el archivo existe antes de enviarlo
        if (!await _imagen!.exists()) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: El archivo de imagen no existe'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        // Verificar el formato de la imagen
        final String extension = _imagen!.path.split('.').last.toLowerCase();
        print("Extensión del archivo: $extension");
        
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          print("ADVERTENCIA: Formato de imagen no estándar: $extension");
        }
        
        // Guardar la ruta de la imagen local para futuras sesiones y sincronización
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('imagen_local_path', _imagen!.path);
        await prefs.setString('imagen_url', 'file://${_imagen!.path}');
        
        // Establecer la bandera de perfil actualizado
        await prefs.setBool('perfil_actualizado', true);
        
      }
      
      final resultado = await userServicio.actualizarPerfil(
        nombre: _nombreController.text,
        email: _emailController.text,
        telefono: _telefonoController.text,
        direccion: _direccionController.text,
        fecha_nacimiento: _fechaNacimiento != null ? DateFormat('yyyy-MM-dd').format(_fechaNacimiento!) : '',
        imagen: _imagen,
      );
      
      if (resultado != null) {
        
        // Verificar si la imagen se actualizó en la respuesta
        if (resultado['usuario'] != null) {
          if (resultado['usuario']['imagen_url'] == null && _imagen != null) {
            // Si la imagen_url es null pero hemos subido una imagen, guardar la ruta local
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('imagen_local_path', _imagen!.path);
          }
        }
        
        // Establecer la bandera de perfil actualizado para que otras pantallas sepan que deben recargar
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('perfil_actualizado', true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: const Color(0xFF4A80F0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Cambiar a modo visualización después de guardar
        setState(() {
          _isEditing = false;
        });
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el perfil'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compresión para reducir el tamaño del archivo
        maxWidth: 600,    // Limitar el ancho máximo
        maxHeight: 600,   // Limitar el alto máximo
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // Verificar que el archivo existe y tiene tamaño
        if (await imageFile.exists()) {
          final fileSize = await imageFile.length();
          print("Imagen seleccionada: ${pickedFile.path}");
          print("Tamaño de la imagen: $fileSize bytes");
          print("Tipo de archivo: ${pickedFile.name.split('.').last}");
          
          // Guardar la ruta de la imagen en SharedPreferences para uso temporal
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('imagen_local_temp', imageFile.path);
          
          setState(() {
            _imagen = imageFile;
          });
        } else {
          print("Error: El archivo de imagen no existe");
        }
      } else {
        print("Selección de imagen cancelada por el usuario");
      }
    } catch (e) {
      print("Error al seleccionar la imagen: $e");
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
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
                            backgroundImage: _getImageProvider(),
                            child: _imagen == null && _imagenExistente == null
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
                   Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 380),
                      child: Text(
                        _nombreController.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
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
                    // Botón de editar/guardar centrado
                    Container(
                      width: 200,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: const Color(0xFF4A80F0),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap: () {
                            if (_isEditing) {
                              _guardarCambios();
                            } else {
                              setState(() {
                                _isEditing = true;
                              });
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEditing ? Icons.save_outlined : Icons.edit_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing ? 'Guardar' : 'Editar',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      if (!_isEditing) ...[
                        Text(
                          'Nombre completo',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
                      
                      // Teléfono
                      if (!_isEditing) ...[
                        Text(
                          'Teléfono',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
                              _telefonoController.text.isEmpty ? 'No especificado' : _telefonoController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                      const SizedBox(height: 16),
                      
                      // Correo electrónico
                      if (!_isEditing) ...[
                        Text(
                          'Correo electrónico',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
                      const SizedBox(height: 16),

                      
                      // Fecha de nacimiento
                      Text(
                        'Fecha de nacimiento',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
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
                      
                      // Dirección
                      if (!_isEditing) ...[
                        Text(
                          'Dirección',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      
                      // Código de referido
                      Text(
                        'Código de referido',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _codigoReferido,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.amber,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: primaryColor),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Código copiado al portapapeles'),
                                  backgroundColor: primaryColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      
                      // Número de referidos
                      Text(
                        'Número de referidos',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _numeroReferido,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                   
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