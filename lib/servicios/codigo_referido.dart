import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_app_flutter/baseUrl.dart';

class CodigoReferidoServicio {
  Future<bool> validarCodigoReferido(String codigo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final url = Uri.parse('$baseUrl/validarCodigoReferido/$codigo');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
         final prefs = await SharedPreferences.getInstance();
         prefs.setString('codigo_referido', codigo);

        print('Código válido: $data');
        return true;
      } else {
        print('Código inválido: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error validando código referido: $e');
      return false;
    }
  }





}
