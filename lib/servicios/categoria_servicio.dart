import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mi_app_flutter/baseUrl.dart';

class CategoriaServicio {
  Future<List<Map<String, dynamic>>?> obtenerCategorias() async {
    final url = Uri.parse("$baseUrl/categoria/");

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print("✅ Categorías obtenidas exitosamente");
        final List<dynamic> data = jsonDecode(response.body);
        print("📊 Cantidad de categorías: ${data.length}");
        return List<Map<String, dynamic>>.from(data);
        
      } else {
        print("❌ Error al obtener categorías: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error al obtener categorías: $e");
      return null;
    }
  }
}
