import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/table_entity.dart';

class PrintService {
  static const String _connectedDeviceKey = 'connected_printer_device';
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;

  // Singleton pattern para mantener la conexión
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  /// Verifica si hay una impresora previamente conectada y trata de reconectarse
  Future<bool> autoConnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceAddress = prefs.getString(_connectedDeviceKey);
      
      if (deviceAddress == null) return false;

      // Buscar el dispositivo por dirección
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final device = bondedDevices.where((d) => d.address == deviceAddress).firstOrNull;
      
      if (device == null) return false;

      return await connectToDevice(device);
    } catch (e) {
      print('🔴 Error en auto-conectar: $e');
      return false;
    }
  }

  /// Conecta a un dispositivo Bluetooth específico
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      // Desconectar conexión previa si existe
      await disconnect();

      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;

      // Guardar dispositivo conectado
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_connectedDeviceKey, device.address);

      print('✅ Conectado a impresora: ${device.name}');
      return true;
    } catch (e) {
      print('🔴 Error conectando a impresora: $e');
      _connection = null;
      _connectedDevice = null;
      return false;
    }
  }

  /// Desconecta la impresora actual
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      _connectedDevice = null;
    } catch (e) {
      print('🔴 Error desconectando impresora: $e');
    }
  }

  /// Verifica si hay una impresora conectada
  bool get isConnected => _connection != null && _connectedDevice != null;

  /// Obtiene el dispositivo conectado actual
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Obtiene lista de impresoras disponibles (dispositivos emparejados)
  Future<List<BluetoothDevice>> getAvailablePrinters() async {
    try {
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      // Filtrar solo impresoras (usualmente contienen estas palabras en el nombre)
      return bondedDevices.where((device) {
        final name = device.name?.toLowerCase() ?? '';
        return name.contains('printer') || 
               name.contains('goojprt') ||
               name.contains('pt') ||
               name.contains('print') ||
               name.contains('pos');
      }).toList();
    } catch (e) {
      print('🔴 Error obteniendo impresoras: $e');
      return [];
    }
  }

  /// Imprime la factura de la orden
  Future<bool> printOrderReceipt({
    required List<OrderItem> orderItems,
    required TableEntity table,
    required String waiterName,
    required String orderId,
    required DateTime orderTime,
  }) async {
    if (!isConnected) {
      print('🔴 No hay impresora conectada');
      return false;
    }

    try {
      final receipt = _buildOrderReceipt(
        orderItems: orderItems,
        table: table,
        waiterName: waiterName,
        orderId: orderId,
        orderTime: orderTime,
      );

      _connection!.output.add(receipt);
      await _connection!.output.allSent;
      
      print('✅ Factura impresa exitosamente');
      return true;
    } catch (e) {
      print('🔴 Error imprimiendo factura: $e');
      return false;
    }
  }

  /// Construye el contenido de la factura para imprimir
  Uint8List _buildOrderReceipt({
    required List<OrderItem> orderItems,
    required TableEntity table,
    required String waiterName,
    required String orderId,
    required DateTime orderTime,
  }) {
    List<int> bytes = [];

    // Comandos ESC/POS para Goojprt PT210
    const int ESC = 0x1B;
    const int GS = 0x1D;
    const int LF = 0x0A;

    // Inicializar impresora
    bytes.addAll([ESC, 0x40]); // ESC @ - Initialize printer

    // Configurar caracteres
    bytes.addAll([ESC, 0x74, 0x00]); // ESC t - Select character code table

    // Centrar texto y agregar logo (simulado con texto)
    bytes.addAll([ESC, 0x61, 0x01]); // ESC a - Center alignment
    bytes.addAll(utf8.encode('*** RESTAURANTE TG ***'));
    bytes.addAll([LF, LF]);

    bytes.addAll(utf8.encode('*** ORDEN DE COCINA ***'));
    bytes.addAll([LF, LF]);

    // Alinear a la izquierda
    bytes.addAll([ESC, 0x61, 0x00]); // ESC a - Left alignment

    // Información de la mesa y mesero
    bytes.addAll(utf8.encode('Mesa: ${table.number}'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('Mesero: $waiterName'));
    bytes.addAll([LF]);

    // Línea separadora
    bytes.addAll(utf8.encode('--------------------------------'));
    bytes.addAll([LF]);

    // Productos
    bytes.addAll(utf8.encode('PRODUCTOS:'));
    bytes.addAll([LF]);

    for (final item in orderItems) {
      // Cantidad y nombre del producto
      bytes.addAll(utf8.encode('${item.quantity}x ${item.product.name}'));
      bytes.addAll([LF]);
      
      // Notas si las hay
      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes.addAll(utf8.encode('   Nota: ${item.notes}'));
        bytes.addAll([LF]);
      }
      bytes.addAll([LF]); // Línea en blanco entre productos
    }

    // Línea separadora
    bytes.addAll(utf8.encode('--------------------------------'));
    bytes.addAll([LF, LF]);

    // ID de la orden
    bytes.addAll(utf8.encode('Orden ID: $orderId'));
    bytes.addAll([LF]);

    // Fecha y hora
    final formattedDate = _formatDateTime(orderTime);
    bytes.addAll(utf8.encode(formattedDate));
    bytes.addAll([LF, LF]);

    // Línea separadora final
    bytes.addAll(utf8.encode('--------------------------------'));
    bytes.addAll([LF, LF, LF]);

    // Cortar papel (si la impresora lo soporta)
    bytes.addAll([GS, 0x56, 0x00]); // GS V - Full cut

    return Uint8List.fromList(bytes);
  }

  /// Formatea la fecha y hora para la factura
  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    
    return '$year-$month-$day $hour:$minute:$second';
  }

  /// Método de prueba para imprimir texto simple
  Future<bool> printTestPage() async {
    if (!isConnected) {
      print('🔴 No hay impresora conectada');
      return false;
    }

    try {
      List<int> bytes = [];
      const int ESC = 0x1B;
      const int LF = 0x0A;

      // Inicializar
      bytes.addAll([ESC, 0x40]);
      
      // Centrar
      bytes.addAll([ESC, 0x61, 0x01]);
      bytes.addAll(utf8.encode('*** PRUEBA DE IMPRESORA ***'));
      bytes.addAll([LF, LF]);
      
      bytes.addAll(utf8.encode('Conexión exitosa'));
      bytes.addAll([LF]);
      bytes.addAll(utf8.encode('Goojprt PT210'));
      bytes.addAll([LF, LF, LF]);

      _connection!.output.add(Uint8List.fromList(bytes));
      await _connection!.output.allSent;
      
      print('✅ Página de prueba impresa');
      return true;
    } catch (e) {
      print('🔴 Error en prueba de impresión: $e');
      return false;
    }
  }
}