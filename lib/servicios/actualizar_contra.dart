import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/baseUrl.dart';

class ActualizarContraServicio {
  Future<String?> actualizarContra(String claveAntigua ,String clave1, String clave2) async {
    final url = Uri.parse("$baseUrl/actualizarContraseña");

    try {
     final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

     final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': claveAntigua,
          'nueva_password': clave1,
          'nueva_password_confirmation': clave2,
        }),
      );


      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        return null;
      } else {
        return data['error'] ?? 'Error al cambiar la contraseña';
      }
    } catch (e) {
      return 'Error de conexión';
    }
  }
}







