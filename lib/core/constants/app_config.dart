/// Configuración de la aplicación para diferentes entornos
class AppConfig {
  // Opciones de desarrollo local
  static const String _emulatorBaseUrl = 'http://10.0.2.2:8080';           // Para Android Emulator
  static const String _localIpBaseUrl = 'http://192.168.1.4:8080';         // Para dispositivos físicos
  static const String _localhostBaseUrl = 'http://localhost:8080';         // Para iOS Simulator
  static const String _prodBaseUrl = 'https://tg-backend-restaurante-prod.onrender.com';
  
  /// Cambia este valor para alternar entre URLs de desarrollo
  /// 0 = Android Emulator (10.0.2.2), 1 = IP Local (192.168.1.4), 2 = Localhost (iOS)
  static const int _localUrlOption = 1;  // Cambiado a IP local
  
  /// Cambia este valor para alternar entre entornos
  /// true = desarrollo local, false = producción
  static const bool _isDevelopment = false;
  
  /// URL base para desarrollo local según la opción seleccionada
  static String get _localBaseUrl {
    switch (_localUrlOption) {
      case 0: return _emulatorBaseUrl;
      case 1: return _localIpBaseUrl;
      case 2: return _localhostBaseUrl;
      default: return _emulatorBaseUrl;
    }
  }
  
  /// URL base actual según el entorno
  static String get baseUrl => _isDevelopment ? _localBaseUrl : _prodBaseUrl;
  
  /// Endpoints de la API
  static const String loginEndpoint = '/api/auth/login';
  static const String tablesEndpoint = '/api/tables';
  
  /// URLs completas
  static String get loginUrl => baseUrl + loginEndpoint;
  static String get tablesUrl => baseUrl + tablesEndpoint;
  
  /// Información del entorno actual
  static String get environment => _isDevelopment ? 'Development' : 'Production';
  
  /// Configuración para debugging
  static bool get isDebugMode => _isDevelopment;
}