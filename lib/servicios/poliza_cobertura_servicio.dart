import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mi_app_flutter/baseUrl.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/archivoService.dart';

class PolizaCobertura {
  final ArchivoService _archivoService = ArchivoService();
  Future<Map<String, dynamic>> obtenerPolizaCobertura() async {
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
        Uri.parse("$baseUrl/polizaCoberturas"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'exito': true, 'polizaCobertura': responseData};
      } else {
        return {
          'exito': false,
          'mensaje': responseData['mensaje'] ?? 'No se encontró la póliza.'
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al obtener pólizas.'};
    }
  }

  Future<String?> descargarDocumentoPoliza(int id, String nombreArchivo) async {
    return await _archivoService.descargarArchivo(
      '/polizaCoberturas/descargar',
      id,
      nombreArchivo,
    );
  }
}
