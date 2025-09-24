import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_app_flutter/baseUrl.dart';

class MigracionServicio {
  Future<Map<String, dynamic>?> obtenerdiasMigratoriasUsuario() async {
    final url = Uri.parse("$baseUrl/diasMigratoriasUsuario");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }



     Future<List<Map<String, dynamic>>?> obtenerMigracionesUsuarios() async {
          final url = Uri.parse("$baseUrl/migracionesUsuarios");

          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('token');

            if (token == null) return null;

            final response = await http.get(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );

            if (response.statusCode == 200) {
              final List<dynamic> data = jsonDecode(response.body);
              return List<Map<String, dynamic>>.from(data);
            

            } else {

              return null;
            }

          } catch (e) {
            return null;
          }
        }

}
