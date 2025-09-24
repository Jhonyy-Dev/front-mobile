import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/baseUrl.dart';

class ValidarCodigoServicio {
  Future<String?> validarCodigo(String codigo) async {
    final url = Uri.parse("$baseUrl/validar-codigo");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('reset_token');
      final email = prefs.getString('reset_email');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'codigo': codigo,
          'token': token,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return null;
      } else {
        return data['error'] ?? 'Código inválido';
      }
    } catch (e) {
      return 'Error de conexión';
    }
  }
}
