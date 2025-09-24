import 'package:html_unescape/html_unescape.dart';

/// Clase utilitaria para corregir problemas de codificación de texto
/// especialmente con acentos y caracteres especiales en español
class TextDecoder {
  static final HtmlUnescape _htmlUnescape = HtmlUnescape();
  
  /// Corrige problemas de codificación en textos con acentos y caracteres especiales
  static String decode(String? text) {
    if (text == null || text.isEmpty) return '';
    
    // Primero intentamos con HtmlUnescape para entidades HTML
    String result = _htmlUnescape.convert(text);
    
    // Mapa de reemplazos específicos para caracteres mal codificados
    final Map<String, String> replacements = {
      // Vocales con acento
      'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú',
      'Ã\u0081': 'Á', 'Ã‰': 'É', 'Ã\u008d': 'Í', 'Ã"': 'Ó', 'Ãš': 'Ú',
      
      // Letra ñ
      'Ã±': 'ñ', 'Ã\u0091': 'Ñ',
      
      // Diéresis
      'Ã¼': 'ü', 'Ãœ': 'Ü',
      
      // Palabras comunes con problemas
      'TomÃ¡s': 'Tomás',
      'RepÃºblica': 'República',
      'JosÃ©': 'José',
      'JirÃ³n': 'Jirón',
      'JunÃ­n': 'Junín',
      'RehabilitaciÃ³n': 'Rehabilitación',
      'PerÃº': 'Perú',
      'MagnÃ³lias': 'Magnólias',
      'AndrÃ©s': 'Andrés',
      'VÃ­gil': 'Vígil',
      'MÃ©dico': 'Médico',
      'ClÃ­nica': 'Clínica',
      'HospitÃ¡l': 'Hospitál',
      
      // Símbolos
      'Â©': '©',
      'Â®': '®',
      'Â°': '°',
      'Âº': 'º',
      'Âª': 'ª',
      'â‚¬': '€',
    };
    
    // Aplicar todos los reemplazos
    replacements.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    
    return result;
  }
}