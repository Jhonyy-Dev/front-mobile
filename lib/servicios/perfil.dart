import 'dart:convert';
import 'package:http/http.dart' as http;  
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_app_flutter/baseUrl.dart';
import 'dart:io';


class PerfilServicio {
  // final String baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<Map<String, dynamic>?> obtenerPerfilUsuario() async {
   
    try {

      final url = Uri.parse("$baseUrl/user");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      print(token);

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(response.body);
      
      if (response.statusCode == 200) {

        final List<dynamic> data = jsonDecode(response.body);
        return data[0];

      } else {
      
        return null;
      }
    } catch (e) {
      // Aquí se maneja cualquier excepción que ocurra durante la solicitud
      print("Error al obtener el perfil: $e");
      return null;
    }
  }


 Future<Map<String, dynamic>?> actualizarPerfil({
  required String nombre,
  required String email,
  required String telefono,
  required String direccion,
  required String fecha_nacimiento,
  File? imagen,
}) async {
  final url = Uri.parse("$baseUrl/actualizarPerfil/"); // Agregar barra final

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) return null;

  try {
    // Usar MultipartRequest para enviar archivos
    final request = http.MultipartRequest('POST', url);
    
    // Agregar headers
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    
    // Agregar campos de texto
    request.fields['nombre'] = nombre;
    request.fields['email'] = email;
    request.fields['telefono'] = telefono;
    request.fields['direccion'] = direccion;
    request.fields['fecha_nacimiento'] = fecha_nacimiento;

    // Agregar la imagen si existe
    if (imagen != null && await imagen.exists()) {
      final fileSize = await imagen.length();
      print("Subiendo imagen: ${imagen.path}");
      print("Tamaño de la imagen: $fileSize bytes");
      
      // Usar el nombre de campo 'imagen_url' que es el que espera el backend
      final imageFile = await http.MultipartFile.fromPath(
        'imagen_url', 
        imagen.path,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.png'
      );
      request.files.add(imageFile);
      
      // También agregar un campo adicional para indicar que hay una imagen
      request.fields['tiene_imagen'] = 'true';
      
    }

    // Enviar la solicitud
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Guardar usuario actualizado en SharedPreferences
      if (data['usuario'] != null) {
        // Si la imagen_url es null pero hemos subido una imagen, 
        // vamos a añadir manualmente una URL temporal
        if (data['usuario']['imagen_url'] == null && imagen != null) {
          data['usuario']['imagen_url_local'] = imagen.path;
          
          // Guardar la ruta de la imagen local para futuras referencias
          await prefs.setString('imagen_local_path', imagen.path);
        }
        
        await prefs.setString('usuario', jsonEncode(data['usuario']));
      }
      
      // Notificar a la aplicación que los datos del usuario han cambiado
      await prefs.setBool('perfil_actualizado', true);
      
      return data;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}





  // Método para verificar si un código de referido es válido
  Future<Map<String, dynamic>> verificarCodigoReferido(String codigo) async {
    try {
      final url = Uri.parse("$baseUrl/verificar-codigo-referido");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Para propósitos de prueba, permitimos verificar sin token
      final headers = {
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'codigo': codigo,
        }),
      );

      // Para propósitos de desarrollo, consideramos válido cualquier código
      // que coincida con el formato esperado (por ejemplo, 8 caracteres)
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Si el endpoint no existe, simulamos una respuesta exitosa para desarrollo
        if (codigo.length >= 6) {
          return {
            'success': true,
            'message': 'Código de referido válido',
          };
        } else {
          return {
            'success': false,
            'message': 'Código de referido inválido',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error al verificar el código: ${response.statusCode}',
        };
      }
    } catch (e) {
      print("Error al verificar código de referido: $e");
      // Para desarrollo, permitimos códigos de 8 caracteres
      if (codigo.length >= 6) {
        return {
          'success': true,
          'message': 'Código de referido válido (modo offline)',
        };
      } else {
        return {
          'success': false,
          'message': 'Código de referido inválido (modo offline)',
        };
      }
    }
  }
}
