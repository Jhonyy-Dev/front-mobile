import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/baseUrl.dart';

class RestablecerContraServicio {

  Future<String?> restablecerContra(String email) async {

    final url = Uri.parse("$baseUrl/recuperar-clave");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('reset_token', data['token']);
        await prefs.setString('reset_email', email);
        return null;

      } else {
       
        return data['message'] ?? 'Ocurrió un error';
        
      }
    } catch (e) {
      return 'Error de conexión';
    }
  }
  
}









