
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_app_flutter/baseUrl.dart';


class RegistrarusuarioServicio {

 Future<Map<String, dynamic>> registrarUsuarioNuevo({
  required String nombre,
  required String email,
  required String password,
}) async {
  try {
    
    final url = Uri.parse('$baseUrl/registrarUsuario');

     final prefs = await SharedPreferences.getInstance();
    final codigoReferido = prefs.getString('codigo_referido') ?? '';

     final body = jsonEncode({
      'nombre': nombre,
      'email': email,
      'password': password,
      'codigo_referido': codigoReferido,
     });

    final response = await http.post(
      url,
       headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
       body: body,
    );

    if (response.statusCode == 201) {
    
      final data = jsonDecode(response.body);
      print('Registro exitoso: $data');
      return {'success': true, 'data': data};

    } else if (response.statusCode == 400 || response.statusCode == 422) {
      // Error de validación (por ejemplo, email en uso)
      final errorData = jsonDecode(response.body);
      print('Errores de validación: $errorData');
      return {'success': false, 'errors': errorData['errors'] ?? errorData};

    } else {
      print('Error inesperado: ${response.body}');
      return {
        'success': false,
        'errors': {'general': ['Error inesperado del servidor']}
      };
    }

  } catch (e) {
    print('Excepción durante registro: $e');
    return {
      'success': false,
      'errors': {'exception': [e.toString()]}
    };
  }
}

}




