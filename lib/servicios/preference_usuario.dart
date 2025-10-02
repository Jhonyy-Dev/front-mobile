 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
 
 
 Future<void> guardarDatosUsuario(String token, Map<String, dynamic> usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('usuario', jsonEncode(usuario));
  }

  Future<Map<String, dynamic>?> obtenerDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final usuarioString = prefs.getString('usuario');

    if (token != null && usuarioString != null) {
      final usuario = jsonDecode(usuarioString);
      return {'token': token, 'usuario': usuario};
    }

    return null;
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  // FUNCIONES ESPECÍFICAS PARA MEDICAL
  Future<void> guardarDatosUsuarioMedical(String token, Map<String, dynamic> usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_medical', token);
    await prefs.setString('usuario_medical', jsonEncode(usuario));
    print('✅ DATOS MEDICAL GUARDADOS:');
    print('   Token: ${token.substring(0, 10)}...');
    print('   Usuario: ${usuario['nombre']}');
  }

  Future<Map<String, dynamic>?> obtenerDatosUsuarioMedical() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_medical');
    final usuarioString = prefs.getString('usuario_medical');

    if (token != null && usuarioString != null) {
      final usuario = jsonDecode(usuarioString);
      return {'token': token, 'usuario': usuario};
    }

    return null;
  }

  Future<void> cerrarSesionMedical() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token_medical');
    await prefs.remove('usuario_medical');
  }

