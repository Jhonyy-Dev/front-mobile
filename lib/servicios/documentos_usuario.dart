import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:mi_app_flutter/baseUrl.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class DocumentoUsuario {
  final Uri url = Uri.parse("$baseUrl/documentosUsuario");

  Future<Map<String, dynamic>> registraDocumento({
    required List<int> archivoBytes,
    required String nombreArchivo,
  }) async {
    try {
      final datosUsuario = await obtenerDatosUsuario();
      if (datosUsuario == null) {
        throw Exception("No hay datos de usuario guardados.");
      }

      final token = datosUsuario['token'];
      final request = http.MultipartRequest('POST', url);

      final archivoMultipart = http.MultipartFile.fromBytes(
        'archivo',
        archivoBytes,
        filename: nombreArchivo,
      );

      request.files.add(archivoMultipart);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      final response = await request.send();

      if (response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        return json.decode(respStr);
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception('Error ${response.statusCode}: $respStr');
      }
    } catch (e) {
      print("Error al subir documento: $e");
      rethrow;
    }
  }



   Future<List<Map<String, dynamic>>> obtenerDocumentos() async {
    final url = Uri.parse("$baseUrl/documentosUsuario/");

    try {
      final datosUsuario = await obtenerDatosUsuario();

      if (datosUsuario == null) {
        throw Exception("No hay datos de usuario guardados.");
      }

      final token = datosUsuario['token'];
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);

      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print("Error al obtener documentos: $e");
      rethrow;
    }
  }



  Future<String?> eliminarDocumento(int documentoId) async {
    try {
      final datosUsuario = await obtenerDatosUsuario();

      if (datosUsuario == null) {
        throw Exception("No hay datos de usuario guardados.");
      }

      final token = datosUsuario['token'];
      final response = await http.delete(
        Uri.parse("$baseUrl/documentosUsuario/$documentoId"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print("Error al eliminar documento: $e");
      rethrow;
    }
  }

Future<String?> descargarDocumento(String nombreDocumento, {String? targetPath}) async {
  try {
    print("🔄 Iniciando descarga de: $nombreDocumento");
    
    // Verificar que el nombre del documento sea válido
    if (nombreDocumento.isEmpty) {
      throw Exception("Nombre de documento inválido");
    }
    
    // En Android, los permisos ya se han solicitado en la pantalla principal
    // Aquí solo verificamos que tengamos acceso al almacenamiento
    if (Platform.isAndroid) {
      print("📱 Verificando acceso al almacenamiento en Android");
      
      // Intentar acceder directamente al directorio de descargas
      try {
        Directory downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          print("⚠️ No se puede acceder al directorio de descargas, puede que falten permisos");
          
          // Intentar solicitar permiso de almacenamiento como último recurso
          var storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            print("⚠️ Permiso de almacenamiento denegado, intentando con directorio de la aplicación");
          }
        }
      } catch (e) {
        print("⚠️ Error al verificar directorio de descargas: $e");
      }
    }

    // Determinar la ruta de destino de manera más robusta
    String filePath;
    if (targetPath != null && targetPath.isNotEmpty) {
      // Usar la ruta especificada
      filePath = targetPath;
      print("📂 Usando ruta especificada: $filePath");
      
      // Asegurar que el directorio exista
      try {
        final directory = Directory(targetPath.substring(0, targetPath.lastIndexOf('/')));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          print("📁 Directorio creado: ${directory.path}");
        }
      } catch (e) {
        print("⚠️ Error al crear directorio: $e");
        // Usar una ruta alternativa si falla la creación del directorio
        final dir = await getApplicationDocumentsDirectory();
        filePath = "${dir.path}/$nombreDocumento";
        print("🔄 Cambiando a ruta alternativa: $filePath");
      }
    } else {
      // Probar múltiples rutas de descarga en orden de preferencia
      String? downloadPath;
      
      if (Platform.isAndroid) {
        // Intentar varias rutas de descarga en Android
        List<String> posiblesRutas = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];
        
        // Probar cada ruta hasta encontrar una que funcione
        for (String ruta in posiblesRutas) {
          try {
            Directory dir = Directory(ruta);
            if (await dir.exists()) {
              downloadPath = ruta;
              print("✅ Ruta de descarga encontrada: $downloadPath");
              break;
            }
          } catch (e) {
            print("⚠️ Error al verificar ruta $ruta: $e");
          }
        }
        
        // Si no se encontró ninguna ruta válida, usar el directorio de la aplicación
        if (downloadPath == null) {
          final dir = await getApplicationDocumentsDirectory();
          downloadPath = dir.path;
          print("⚠️ No se encontró directorio de descargas, usando: $downloadPath");
        }
      } else {
        // iOS: usa el directorio interno ya que no hay carpeta pública de descargas
        final dir = await getApplicationDocumentsDirectory();
        downloadPath = dir.path;
        print("📱 iOS: usando directorio de documentos: $downloadPath");
      }
      
      filePath = "$downloadPath/$nombreDocumento";
    }

    // Verificar si el archivo ya existe y añadir un sufijo único si es necesario
    try {
      File file = File(filePath);
      if (await file.exists()) {
        // Si el archivo ya existe, añadir timestamp para hacerlo único
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = nombreDocumento.contains('.') 
            ? nombreDocumento.substring(nombreDocumento.lastIndexOf('.'))
            : '';
        final baseName = nombreDocumento.contains('.') 
            ? nombreDocumento.substring(0, nombreDocumento.lastIndexOf('.'))
            : nombreDocumento;
        
        filePath = "${filePath.substring(0, filePath.lastIndexOf('/'))}/$baseName-$timestamp$extension";
        print("🔄 El archivo ya existe, usando nuevo nombre: $filePath");
      }
    } catch (e) {
      print("⚠️ Error al verificar si el archivo existe: $e");
    }

    // Obtener token para la autenticación
    final datosUsuario = await obtenerDatosUsuario();
    if (datosUsuario == null || datosUsuario['token'] == null) {
      throw Exception("No hay token de autenticación disponible");
    }
    
    final token = datosUsuario['token'];
    final url = "$baseUrl/documentos/descargar/$nombreDocumento";
    print("🌐 URL de descarga: $url");

    // Configurar Dio con timeout y reintentos
    Dio dio = Dio();
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 60);
    dio.options.followRedirects = true;
    
    print("⬇️ Iniciando descarga a: $filePath");
    
    // Intentar la descarga con reintentos
    int intentos = 0;
    int maxIntentos = 3;
    Exception? ultimoError;
    
    while (intentos < maxIntentos) {
      try {
        await dio.download(
          url,
          filePath,
          options: Options(headers: {
            'Authorization': 'Bearer $token',
            'Accept': '*/*', // Aceptar cualquier tipo de contenido
            'Connection': 'keep-alive',
          }),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              int porcentaje = ((received / total) * 100).round();
              print("📊 Progreso: $porcentaje% ($received/$total bytes)");
            }
          },
        );

        // Verificar que el archivo se haya descargado correctamente
        File file = File(filePath);
        if (await file.exists()) {
          int fileSize = await file.length();
          if (fileSize > 0) {
            print("✅ Documento descargado exitosamente en: $filePath");
            print("📊 Tamaño del archivo: $fileSize bytes");
            return filePath;
          } else {
            throw Exception("El archivo descargado está vacío");
          }
        } else {
          throw Exception("No se pudo crear el archivo en la ruta especificada");
        }
      } catch (e) {
        intentos++;
        ultimoError = Exception("Intento $intentos fallido: $e");
        print("⚠️ $ultimoError");
        
        if (intentos < maxIntentos) {
          print("🔄 Reintentando descarga en 2 segundos...");
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
    
    throw ultimoError ?? Exception("Falló la descarga después de $maxIntentos intentos");
  } catch (e) {
    print("❌ Error al descargar el documento: $e");
    return null;
  }
}


}
