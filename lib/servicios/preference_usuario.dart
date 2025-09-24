 
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

