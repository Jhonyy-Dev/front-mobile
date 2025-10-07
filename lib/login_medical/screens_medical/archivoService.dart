import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mi_app_flutter/baseUrl.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';

class ArchivoService {
  
  Future<String?> descargarArchivo(String ruta, int id, String nombreArchivo) async {
    try {
      final datosUsuario = await obtenerDatosUsuario();
      if (datosUsuario == null || datosUsuario['token'] == null) {
        throw Exception("No se encontró el token de autenticación");
      }

      final String token = datosUsuario['token'];
      final String url = "$baseUrl$ruta/$id";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': '*/*',
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Error al descargar el archivo (${response.statusCode})");
      }

      Directory dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = Directory.systemTemp;
      }

      final String path = '${dir.path}/$nombreArchivo';
      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);

      return path;
    } catch (e) {
      print('Error al descargar archivo: $e');
      return null;
    }
  }
}
