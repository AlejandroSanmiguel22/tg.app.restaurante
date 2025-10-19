import 'package:dio/dio.dart';
import '../../domain/entities/order_item_entity.dart';
import '../constants/app_config.dart';
import 'auth_service.dart';

class OrderService {
  final Dio _dio;
  
  OrderService(this._dio);
  
  /// Crear una nueva orden
  Future<bool> createOrder({
    required String tableId,
    required String waiterId,
    required List<OrderItem> items,
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }
      
      final orderData = {
        'tableId': tableId,
        'waiterId': waiterId,
        'items': items.map((item) => item.toJson()).toList(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      
      print('🔵 Creando orden con datos: $orderData');
      
      final response = await _dio.post(
        '${AppConfig.baseUrl}/api/orders',
        data: orderData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('🔵 Respuesta de crear orden: ${response.statusCode}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('🔴 Error Dio al crear orden: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Token de autenticación inválido');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      print('🔴 Error inesperado al crear orden: $e');
      throw Exception('Error inesperado: $e');
    }
  }
}