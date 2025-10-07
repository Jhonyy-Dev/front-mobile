import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mi_app_flutter/baseUrl.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';

class TarjetaDigital {
  
  Future<Map<String, dynamic>> obtenerTarjetaDigital() async {
    try {
      final datosUsuario = await obtenerDatosUsuario();

      if (datosUsuario == null || datosUsuario['token'] == null) {
        return {
          'exito': false,
          'mensaje': 'Error: No se encontró el usuario o el token.'
        };
      }

      final String token = datosUsuario['token'];
      final response = await http.get(
        Uri.parse("$baseUrl/tarjetaDigital"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'exito': true, 'tarjetaDigital': responseData};
      } else {
        return {
          'exito': false,
          'mensaje': responseData['mensaje'] ?? 'No se encontró la tarjeta digital.'
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al obtener la tarjeta digital.'};
    }
  }

  
}
