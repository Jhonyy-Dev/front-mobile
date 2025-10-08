class ApiConfig {
  // URL base de la API de Laravel
  static const String baseUrl = "https://inmigracion.maval.tech/api";
  
  // URL base para archivos de storage
  static const String storageUrl = "https://inmigracion.maval.tech/storage";
  
  // Endpoints específicos
  static const String loginEndpoint = "/login";
  static const String registerEndpoint = "/registrarUsuario";
  static const String userEndpoint = "/user";
  static const String updateProfileEndpoint = "/actualizarPerfil";
  static const String documentsEndpoint = "/documentosUsuario";
  static const String appointmentsEndpoint = "/citas";
  static const String categoriesEndpoint = "/categoria";
  static const String migrationsEndpoint = "/migracionesUsuarios";
  static const String migrationDaysEndpoint = "/diasMigratoriasUsuario";
  static const String validateCodeEndpoint = "/validar-codigo";
  static const String resetPasswordEndpoint = "/recuperar-clave";
  static const String changePasswordEndpoint = "/cambiar-clave";
  static const String updatePasswordEndpoint = "/actualizarContraseña";
  static const String validateReferralEndpoint = "/validarCodigoReferido";
  static const String verifyReferralEndpoint = "/verificar-codigo-referido";
  static const String logoutEndpoint = "/logout";
  
  // Métodos helper para construir URLs completas
  static String getFullUrl(String endpoint) {
    return "$baseUrl$endpoint";
  }
  
  static String getUserImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    return "$storageUrl/usuarios/$imagePath";
  }
  
  // Headers comunes para las peticiones
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Headers para peticiones multipart
  static Map<String, String> getMultipartHeaders({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
}
