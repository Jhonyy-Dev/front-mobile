import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/baseUrl.dart';

class CerrarSesionService {
  final Uri url = Uri.parse("$baseUrl/logout");

  Future<bool> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        
        await prefs.remove('token');
        await prefs.remove('usuario'); 
        
        return true;
      } else {
        print('Error al cerrar sesión: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción al cerrar sesión: $e');
      return false;
    }
  }
}
