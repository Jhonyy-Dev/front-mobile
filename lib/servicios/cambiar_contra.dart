import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/baseUrl.dart';

class CambiarContraServicio {
  Future<String?> cambiarContra(String clave1 , String clave2) async {
    final url = Uri.parse("$baseUrl/cambiar-clave");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('reset_token');
      final email = prefs.getString('reset_email');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'password': clave1,
          'password_confirmation': clave2,
        }),
      );

      final data = jsonDecode(response.body);

     if (response.statusCode == 200) {
      
        await prefs.remove('reset_token');
        await prefs.remove('reset_email');
        return null;
        
      } else {
        return data['error'] ?? 'Error al cambiar la contraseña';
      }
    } catch (e) {
      return 'Error de conexión';
    }
  }
}
