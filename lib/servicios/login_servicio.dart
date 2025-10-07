import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/baseUrl.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';

class AuthService {

  Future<Map<String, dynamic>> login(String email, String password) async {

   final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
      
        await guardarDatosUsuario(data['token'], data['user']);

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['mensaje'] ?? 'Credenciales incorrectas'};
      }
     } catch (e, stacktrace) {
      print("Error: $e");
     print("Stacktrace: $stacktrace");

      return {'success': false, 'message': 'Error en la conexión'};
    }
  }


 

}
