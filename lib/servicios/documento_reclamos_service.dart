import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mi_app_flutter/baseUrl.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/archivoService.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';

class DocumentoReclamosService {
  final ArchivoService _archivoService = ArchivoService();


  Future<Map<String, dynamic>> obtenerRecibidos() async {
    try {
      final datosUsuario = await obtenerDatosUsuario();
      if (datosUsuario == null || datosUsuario['token'] == null) {
        return {'exito': false, 'mensaje': 'Usuario o token no encontrado'};
      }

      final String token = datosUsuario['token'];
      final response = await http.get(
        Uri.parse("$baseUrl/documentoReclamos/recibidos"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'mensaje': 'Error al obtener documentos recibidos (${response.statusCode})'
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> obtenerSubidos() async {
    try {
      final datosUsuario = await obtenerDatosUsuario();
      if (datosUsuario == null || datosUsuario['token'] == null) {
        return {'exito': false, 'mensaje': 'Usuario o token no encontrado'};
      }

      final String token = datosUsuario['token'];
      final response = await http.get(
        Uri.parse("$baseUrl/documentoReclamos/subidos"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'mensaje': 'Error al obtener documentos subidos (${response.statusCode})'
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> subirDocumento(File archivo) async {
    try {
      final datosUsuario = await obtenerDatosUsuario();
      if (datosUsuario == null || datosUsuario['token'] == null) {
        return {'exito': false, 'mensaje': 'Usuario o token no encontrado'};
      }

      final String token = datosUsuario['token'];
      final uri = Uri.parse("$baseUrl/documentoReclamos");
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('documento', archivo.path));

      final response = await request.send();

      if (response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'mensaje': 'Error al subir el documento (${response.statusCode})'
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: $e'};
    }
  }



 Future<String?> descargarDocumentoReclamo(int id, String nombreArchivo) async {
    return await _archivoService.descargarArchivo(
      '/documentoReclamos/descargar',
      id, 
      nombreArchivo,
    );
  }

  Future<void> eliminarDocumentoReclamo(int id) async {
    try {
      final datosUsuario = await obtenerDatosUsuario();
      if (datosUsuario == null || datosUsuario['token'] == null) {
        return;
      }

      final String token = datosUsuario['token'];
      final response = await http.delete(
        Uri.parse("$baseUrl/documentoReclamos/$id"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else {
        return;
      }
    } catch (e) {
      return;
    }
  }


}
