import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/baseUrl.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';


class CitasServicio {
  final Uri url = Uri.parse("$baseUrl/citas");

  Future<Map<String, dynamic>> registrarCita({
    required String fechaCita,
    required String horaCita,
    required int categoriaId,

  }) async {
    try {
      final datosUsuario = await obtenerDatosUsuario();

      if (datosUsuario == null) {
        return {'exito': false, 'mensaje': 'Error: No se encontró el usuario o el token.'};
      }

      final token = datosUsuario['token'];
      final usuario = datosUsuario['usuario'];
      final usuarioId = usuario['id'];

      final body = jsonEncode({
        "usuario_id": usuarioId,
        "fecha_cita": fechaCita,
        "hora_cita": horaCita,
        "estado": "Pendiente",
        "categoria_id": categoriaId,
      });

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {

        return {'exito': true, 'mensaje': 'Cita registrada correctamente.'};
      } else {
        return {'exito': false, 'mensaje': 'Error al registrar la cita.'};
      }

    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al registrar la cita.'};
    }

  }


 Future<Map<String, dynamic>> obtenerCitas() async {
    try {
      final datosUsuario = await obtenerDatosUsuario();

      if (datosUsuario == null) {
        return {'exito': false, 'mensaje': 'Error: No se encontró el usuario o el token.'};
      }

      final String token = datosUsuario['token'];
      final String userId = datosUsuario['usuario']['id'].toString();
      final String userName = datosUsuario['usuario']['nombre'];
      

      final response = await http.get(
        Uri.parse("$baseUrl/citasUsuarios"), 
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('prueba'+ response.body);
      final responseData = jsonDecode(response.body);
    
      if (response.statusCode == 200) {
        return {'exito': true, 'citas': responseData};
      } else {
        return {'exito': false, 'mensaje': responseData['mensaje'] ?? 'no se encontro citas'};
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'no se encontro citas'};
    }
  }


    Future<String?> eliminarCita(int citaId) async {
    try {
      final datosUsuario = await obtenerDatosUsuario();

      final token = datosUsuario?['token'];
      

      final response = await http.delete(
        
        Uri.parse("$baseUrl/citas/$citaId/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        return 'Error al eliminar la cita.';
      }
    } catch (e) {
      return 'Error en la conexión: $e';
    }
  }




}




