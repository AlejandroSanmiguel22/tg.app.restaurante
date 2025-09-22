// Datasource para autenticación de usuario
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_config.dart';

abstract class LoginDatasource {
  Future<Map<String, dynamic>> login({required String userName, required String password});
}

class LoginDatasourceImpl implements LoginDatasource {
  final Dio dio;
  LoginDatasourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> login({required String userName, required String password}) async {
    print('🔵 LoginDatasource: Iniciando login...');
    print('🔵 URL: ${AppConfig.loginUrl}');
    print('🔵 Usuario: $userName');
    print('🔵 Connect Timeout: ${dio.options.connectTimeout}');
    print('🔵 Receive Timeout: ${dio.options.receiveTimeout}');
    print('🔵 Send Timeout: ${dio.options.sendTimeout}');
    
    try {
      final response = await dio.post(
        AppConfig.loginUrl,
        data: {
          'userName': userName,
          'password': password,
        },
      );
      
      print('✅ LoginDatasource: Respuesta exitosa');
      print('✅ Status Code: ${response.statusCode}');
      print('✅ Data: ${response.data}');
      
      return response.data;
    } catch (e) {
      print('❌ LoginDatasource: Error en login');
      print('❌ Error: $e');
      rethrow;
    }
  }
} 