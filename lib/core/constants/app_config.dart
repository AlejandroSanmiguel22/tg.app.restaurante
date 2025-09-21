/// Configuración de la aplicación para diferentes entornos
class AppConfig {
  static const String _localBaseUrl = 'http://localhost:8080';
  static const String _prodBaseUrl = 'https://tg-backend-restaurante-prod.onrender.com';
  
  /// Cambia este valor para alternar entre entornos
  /// true = desarrollo local, false = producción
  static const bool _isDevelopment = false;
  
  /// URL base actual según el entorno
  static String get baseUrl => _isDevelopment ? _localBaseUrl : _prodBaseUrl;
  
  /// Endpoints de la API
  static const String loginEndpoint = '/api/auth/login';
  
  /// URL completa para login
  static String get loginUrl => baseUrl + loginEndpoint;
  
  /// Información del entorno actual
  static String get environment => _isDevelopment ? 'Development' : 'Production';
  
  /// Configuración para debugging
  static bool get isDebugMode => _isDevelopment;
}