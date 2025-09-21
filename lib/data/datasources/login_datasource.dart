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
    final response = await dio.post(
      AppConfig.loginUrl,
      data: {
        'userName': userName,
        'password': password,
      },
    );
    // Ejemplo de guardado de token (la lógica real irá en el Bloc o repositorio)
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('token', response.data['token']);
    return response.data;
  }
} 