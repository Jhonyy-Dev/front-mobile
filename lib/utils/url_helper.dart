import '../config/api_config.dart';

class UrlHelper {
  /// Construye la URL completa para archivos de storage
  /// Maneja correctamente rutas relativas y absolutas
  static String getStorageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    
    // Si ya es una URL completa, devolverla tal cual
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    // Si es una ruta file:// (imagen local), devolverla tal cual
    if (path.startsWith('file://')) {
      return path;
    }
    
    // Si es una ruta relativa del servidor, construir URL completa
    // IMPORTANTE: NO agregar prefijos adicionales porque el backend 
    // ya incluye la carpeta (ej: "usuarios/", "categorias/", etc.)
    return '${ApiConfig.storageUrl}/$path';
  }
  
  /// Construye URL completa para imágenes de usuario
  static String getUserImageUrl(String? imagePath) {
    return getStorageUrl(imagePath);
  }
  
  /// Construye URL completa para imágenes de categorías
  static String getCategoryImageUrl(String? imagePath) {
    return getStorageUrl(imagePath);
  }
}
