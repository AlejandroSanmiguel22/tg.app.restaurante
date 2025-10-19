import 'package:dio/dio.dart';
import '../../domain/entities/product_entity.dart';
import '../constants/app_config.dart';
import 'auth_service.dart';

class ProductService {
  final Dio _dio;
  
  ProductService(this._dio);
  
  /// Obtener todos los productos del menú
  Future<List<Product>> getProducts() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }
      
      print('🔵 Obteniendo productos de: ${AppConfig.baseUrl}/api/productes');
      
      final response = await _dio.get(
        '${AppConfig.baseUrl}/api/productes',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('🔵 Respuesta productos - Status: ${response.statusCode}');
      print('🔵 Respuesta productos - Data: ${response.data}');
      
      if (response.statusCode == 200) {
        // La respuesta puede ser directamente un array o estar dentro de un objeto 'data'
        List<dynamic> productsJson;
        if (response.data is List) {
          productsJson = response.data;
        } else if (response.data is Map && response.data['data'] != null) {
          productsJson = response.data['data'];
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
        
        print('🔵 Productos encontrados: ${productsJson.length}');
        final products = productsJson.map((json) => Product.fromJson(json)).toList();
        
        for (var product in products) {
          print('🔵 Producto parseado: ${product.name} - \$${product.price}');
        }
        
        return products;
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('🔴 Error Dio al obtener productos: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Token de autenticación inválido');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      print('🔴 Error inesperado al obtener productos: $e');
      throw Exception('Error inesperado: $e');
    }
  }
}