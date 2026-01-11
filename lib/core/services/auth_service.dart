import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar la autenticación y persistencia de sesión
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';
  
  /// Guardar datos de sesión después del login
  static Future<void> saveSession({
    required String token,
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userRoleKey, userRole);
  }
  
  /// Obtener el token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  /// Obtener datos del usuario guardado
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_userIdKey),
      'userName': prefs.getString(_userNameKey),
      'userRole': prefs.getString(_userRoleKey),
    };
  }
  
  /// Verificar si hay una sesión activa
  static Future<bool> hasActiveSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Limpiar toda la sesión (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
  }
  
  /// Verificar si el token es válido (puedes expandir esto más adelante)
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    
    // TODO: Aquí puedes agregar lógica para verificar expiración
    // Por ejemplo, hacer una llamada al backend para validar el token
    
    return true;
  }
}