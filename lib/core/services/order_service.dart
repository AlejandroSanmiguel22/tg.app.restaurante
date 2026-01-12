import 'package:dio/dio.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/order_entity.dart';
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

  /// Obtener la orden activa de una mesa
  Future<OrderEntity?> getActiveOrderByTable(String tableId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }
      
      print('🔵 Obteniendo orden activa para mesa: $tableId');
      
      final response = await _dio.get(
        '${AppConfig.baseUrl}/api/orders/table/$tableId/active',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('🔵 Respuesta orden activa: ${response.statusCode}');
      print('🔵 Datos orden activa: ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        return OrderEntity.fromJson(response.data['data']);
      }
      
      return null;
    } on DioException catch (e) {
      print('🔴 Error Dio al obtener orden activa: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        // No hay orden activa para esta mesa
        return null;
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Token de autenticación inválido');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      print('🔴 Error inesperado al obtener orden activa: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Generar factura para una orden y obtener los datos con opción de propina
  Future<Map<String, dynamic>?> generateBillDataWithTip(String orderId, bool withTip) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }
      
      print('🔵 Generando factura para orden: $orderId con propina: $withTip');
      
      final response = await _dio.post(
        '${AppConfig.baseUrl}/api/orders/$orderId/bill',
        data: {
          'withTip': withTip ? 'yes' : 'no',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('🔵 Respuesta generar factura con tip: ${response.statusCode}');
      print('🔵 Datos de la factura: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      }
      
      return null;
    } catch (e) {
      print('🔴 Error al generar factura con tip: $e');
      rethrow;
    }
  }

  /// Generar factura para una orden y obtener los datos
  Future<Map<String, dynamic>?> generateBillData(String orderId) async {
    return generateBillDataWithTip(orderId, true); // Por defecto con propina
  }

  /// Generar factura para una orden (método existente para compatibilidad)
  Future<bool> generateBill(String orderId) async {
    try {
      final billData = await generateBillData(orderId);
      return billData != null;
    } catch (e) {
      print('🔴 Error al generar factura: $e');
      return false;
    }
  }

  /// Cerrar una orden
  Future<bool> closeOrder(String orderId, bool withTip) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }
      
      print('🔵 Cerrando orden: $orderId con tip: $withTip');
      
      final response = await _dio.post(
        '${AppConfig.baseUrl}/api/orders/$orderId/close',
        data: {
          'withTip': withTip ? 'yes' : 'no',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('🔵 Respuesta cerrar orden: ${response.statusCode}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('🔴 Error Dio al cerrar orden: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Token de autenticación inválido');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      print('🔴 Error inesperado al cerrar orden: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Agregar productos a una orden existente
  Future<OrderEntity?> addItemsToOrder(String orderId, List<OrderItem> items) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }
      
      final requestData = {
        'items': items.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
        }).toList(),
      };
      
      print('🔵 Agregando items a orden: $orderId con datos: $requestData');
      
      final response = await _dio.post(
        '${AppConfig.baseUrl}/api/orders/$orderId/items',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('🔵 Respuesta agregar items: ${response.statusCode}');
      print('🔵 Datos respuesta: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return OrderEntity.fromJson(response.data['data']);
      }
      
      return null;
    } on DioException catch (e) {
      print('🔴 Error Dio al agregar items a orden: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Token de autenticación inválido');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      print('🔴 Error inesperado al agregar items a orden: $e');
      throw Exception('Error inesperado: $e');
    }
  }
}