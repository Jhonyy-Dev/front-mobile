import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/servicios/perfil.dart';

class UserProfileProvider with ChangeNotifier {
  String _nombre = 'Usuario';
  String _telefono = '';
  String _email = '';
  String _direccion = '';
  String _fechaNacimiento = '';
  String _imagenUrl = '';
  String _codigoReferido = '';
  bool _isLoading = true;
  File? _imagenLocal;

  // Getters
  String get nombre => _nombre;
  String get telefono => _telefono;
  String get email => _email;
  String get direccion => _direccion;
  String get fechaNacimiento => _fechaNacimiento;
  String get imagenUrl => _imagenUrl;
  String get codigoReferido => _codigoReferido;
  bool get isLoading => _isLoading;
  File? get imagenLocal => _imagenLocal;

  final PerfilServicio _perfilServicio = PerfilServicio();

  // Constructor que carga los datos al inicializar
  UserProfileProvider() {
    cargarDatosPerfil();
  }

  // Método para cargar datos del perfil desde el servidor y SharedPreferences
  Future<void> cargarDatosPerfil() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Primero intentar obtener datos guardados en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final nombreGuardado = prefs.getString('nombre_usuario');
      final imagenGuardada = prefs.getString('imagen_url');
      
      // Si hay datos guardados, usarlos temporalmente mientras se cargan los del servidor
      if (nombreGuardado != null) {
        _nombre = nombreGuardado;
        if (imagenGuardada != null && imagenGuardada.isNotEmpty) {
          _imagenUrl = imagenGuardada;
        }
        notifyListeners();
      }
      
      // Luego intentar obtener datos actualizados del servidor
      final perfilData = await _perfilServicio.obtenerPerfilUsuario();
      
      if (perfilData != null) {
        // Actualizar con datos del servidor
        _nombre = perfilData['nombre'] ?? nombreGuardado ?? 'Usuario';
        _telefono = perfilData['telefono'] ?? '';
        _email = perfilData['email'] ?? '';
        _direccion = perfilData['direccion'] ?? '';
        _codigoReferido = perfilData['codigo_referido'] ?? '';
        
        // Para la imagen, priorizar la de SharedPreferences si existe (más reciente)
        if (imagenGuardada != null && imagenGuardada.isNotEmpty) {
          _imagenUrl = imagenGuardada;
        } else if (perfilData['imagen_url'] != null && perfilData['imagen_url'].toString().isNotEmpty) {
          _imagenUrl = perfilData['imagen_url'];
          // Guardar la URL para sincronización
          await prefs.setString('imagen_url', _imagenUrl);
        }
        
        // Guardar datos actualizados en SharedPreferences
        await prefs.setString('nombre_usuario', _nombre);
        
        // Manejar fecha de nacimiento si existe
        if (perfilData['fecha_nacimiento'] != null && 
            perfilData['fecha_nacimiento'].toString().isNotEmpty) {
          try {
            final fecha = DateTime.parse(perfilData['fecha_nacimiento']);
            _fechaNacimiento = '${fecha.day}/${fecha.month}/${fecha.year}';
          } catch (e) {
            print('Error al parsear la fecha: $e');
            _fechaNacimiento = '';
          }
        }
        
        print("✅ Datos de usuario cargados en Provider: $_nombre");
      }
      
      // Verificar si hay una imagen local guardada
      await _verificarImagenLocal();
      
    } catch (e) {
      print('❌ Error al cargar datos del perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para verificar y cargar imagen local
  Future<void> _verificarImagenLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Si no hay imagen URL del servidor, intentar usar la imagen local
      if (_imagenUrl.isEmpty) {
        final imagenLocalPath = prefs.getString('imagen_local_path');
        
        if (imagenLocalPath != null) {
          final file = File(imagenLocalPath);
          if (await file.exists()) {
            _imagenUrl = 'file://$imagenLocalPath';
            _imagenLocal = file;
            
            // Guardar para sincronización
            await prefs.setString('imagen_url', _imagenUrl);
            print("✅ Usando imagen local en Provider: $_imagenUrl");
            notifyListeners();
          }
        }
      } else if (_imagenUrl.startsWith('file://')) {
        // Si la imagen es local, cargar el archivo
        final path = _imagenUrl.replaceFirst('file://', '');
        final file = File(path);
        if (await file.exists()) {
          _imagenLocal = file;
        }
      }
    } catch (e) {
      print("❌ Error al verificar imagen local: $e");
    }
  }

  // Método para actualizar datos del perfil
  Future<bool> actualizarPerfil({
    required String nombre,
    required String email,
    required String telefono,
    required String direccion,
    String? fechaNacimiento,
    File? imagen,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final resultado = await _perfilServicio.actualizarPerfil(
        nombre: nombre,
        email: email,
        telefono: telefono,
        direccion: direccion,
        fecha_nacimiento: fechaNacimiento ?? '',
        imagen: imagen,
      );
      
      if (resultado != null) {
        // Actualizar datos locales
        _nombre = nombre;
        _email = email;
        _telefono = telefono;
        _direccion = direccion;
        
        // Guardar en SharedPreferences para sincronización
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nombre_usuario', nombre);
        
        // Si se actualizó la imagen
        if (imagen != null) {
          _imagenLocal = imagen;
          
          // Verificar si el servidor devolvió una URL de imagen
          if (resultado['usuario'] != null && 
              resultado['usuario']['imagen_url'] != null && 
              resultado['usuario']['imagen_url'].toString().isNotEmpty) {
            
            _imagenUrl = resultado['usuario']['imagen_url'];
          } else {
            // Usar ruta local como URL
            _imagenUrl = 'file://${imagen.path}';
            await prefs.setString('imagen_local_path', imagen.path);
          }
          
          // Guardar URL para sincronización
          await prefs.setString('imagen_url', _imagenUrl);
        }
        
        print("✅ Perfil actualizado en Provider: $_nombre");
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error al actualizar perfil: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
