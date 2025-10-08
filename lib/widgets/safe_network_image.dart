import 'dart:io';
import 'package:flutter/material.dart';

/// ImageProvider que devuelve el provider correcto según el tipo de URL
/// Maneja errores silenciosamente usando el errorBuilder del Image widget
class SafeNetworkImageProvider extends ImageProvider<Object> {
  final String? url;
  final ImageProvider fallback;
  
  const SafeNetworkImageProvider({
    required this.url,
    required this.fallback,
  });

  ImageProvider _getActualProvider() {
    // Si la URL es null o vacía, usar fallback
    if (url == null || url!.isEmpty) {
      return fallback;
    }

    // Si es una imagen local (file://), usar FileImage
    if (url!.startsWith('file://')) {
      try {
        final localPath = url!.replaceFirst('file://', '');
        return FileImage(File(localPath));
      } catch (e) {
        return fallback;
      }
    }

    // Si es una URL de red, usar NetworkImage
    final networkUrl = url!.startsWith('http') 
        ? url! 
        : "https://inmigracion.maval.tech/storage/$url";
    
    return NetworkImage(networkUrl);
  }

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    return _getActualProvider().obtainKey(configuration);
  }

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) {
    final provider = _getActualProvider();
    
    // Si es el fallback, cargarlo directamente
    if (provider == fallback) {
      return provider.loadImage(key as dynamic, decode);
    }
    
    // Si es NetworkImage o FileImage, intentar cargar con manejo de errores
    final completer = provider.loadImage(key as dynamic, decode);
    
    // Retornar el completer original - el errorBuilder del widget manejará errores
    return completer;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is SafeNetworkImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
