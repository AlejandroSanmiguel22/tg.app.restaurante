// Datasource para obtener información de las mesas
import 'package:dio/dio.dart';
import '../../core/constants/app_config.dart';
import '../../core/services/auth_service.dart';

abstract class TableDatasource {
  Future<Map<String, dynamic>> getTables();
}

class TableDatasourceImpl implements TableDatasource {
  final Dio dio;
  
  TableDatasourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> getTables() async {
    final String tablesUrl = AppConfig.tablesUrl;
    
    print('🔵 TableDatasource: Obteniendo mesas...');
    print('🔵 URL: $tablesUrl');
    
    // Obtener el token de autenticación
    final token = await AuthService.getToken();
    print('🔵 Token disponible: ${token != null ? "Sí" : "No"}');
    
    try {
      final response = await dio.get(
        tablesUrl,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('✅ TableDatasource: Respuesta exitosa');
      print('✅ Status Code: ${response.statusCode}');
      print('✅ Total mesas: ${(response.data['data'] as List).length}');
      
      return response.data;
    } catch (e) {
      print('❌ TableDatasource: Error al obtener mesas');
      print('❌ Error: $e');
      rethrow;
    }
  }
}