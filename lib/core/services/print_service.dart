import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/table_entity.dart';

enum PrinterType { main }

class PrinterConnection {
  BluetoothConnection? connection;
  BluetoothDevice? device;
  PrinterType type;

  PrinterConnection({
    required this.type,
    this.connection,
    this.device,
  });

  bool get isConnected => connection != null && device != null;
}

class PrintService {
  static const String _mainPrinterKey = 'main_printer_device';
  
  final Map<PrinterType, PrinterConnection> _printers = {
    PrinterType.main: PrinterConnection(type: PrinterType.main),
  };

  // Singleton pattern para mantener las conexiones
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  /// Verifica si hay impresoras previamente conectadas y trata de reconectarse
  Future<bool> autoConnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool anyConnected = false;
      
      print('🔵 Iniciando auto-conexión...');
      
      // Intentar reconectar impresora principal
      final mainAddress = prefs.getString(_mainPrinterKey);
      if (mainAddress != null) {
        print('🔵 Intentando reconectar impresora principal: $mainAddress');
        final success = await _reconnectPrinter(mainAddress, PrinterType.main);
        if (success) {
          anyConnected = true;
          print('✅ Impresora principal reconectada exitosamente');
        } else {
          print('🔴 No se pudo reconectar impresora principal');
        }
      } else {
        print('🔵 No hay dirección guardada para impresora principal');
      }

      print('🔵 Auto-conexión completada. Alguna conectada: $anyConnected');
      return anyConnected;
    } catch (e) {
      print('🔴 Error en auto-conectar: $e');
      return false;
    }
  }

  Future<bool> _reconnectPrinter(String deviceAddress, PrinterType type) async {
    try {
      print('🔵 Buscando dispositivo ${type.name} con dirección: $deviceAddress');
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final device = bondedDevices.where((d) => d.address == deviceAddress).firstOrNull;
      
      if (device == null) {
        print('🔴 No se encontró dispositivo con dirección $deviceAddress');
        return false;
      }

      print('🔵 Dispositivo ${type.name} encontrado: ${device.name}');
      return await connectToDevice(device, type);
    } catch (e) {
      print('🔴 Error reconectando ${type.name}: $e');
      return false;
    }
  }

  /// Conecta a un dispositivo Bluetooth específico
  Future<bool> connectToDevice(BluetoothDevice device, PrinterType type) async {
    try {
      // Verificar si ya está conectado al mismo dispositivo
      final currentConnection = _printers[type];
      if (currentConnection?.device?.address == device.address && currentConnection!.isConnected) {
        print('✅ Ya conectado a ${device.name} como ${type.name}');
        return true;
      }

      // Desconectar conexión previa del mismo tipo si existe
      await disconnect(type);

      print('🔵 Conectando a ${device.name} como ${type.name}...');
      final connection = await BluetoothConnection.toAddress(device.address);
      
      _printers[type] = PrinterConnection(
        type: type,
        connection: connection,
        device: device,
      );

      // Guardar dispositivo conectado
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mainPrinterKey, device.address);

      print('✅ Conectado a impresora ${type.name}: ${device.name}');
      return true;
    } catch (e) {
      print('🔴 Error conectando a impresora ${type.name}: $e');
      _printers[type] = PrinterConnection(type: type);
      return false;
    }
  }

  /// Desconecta la impresora del tipo especificado
  Future<void> disconnect(PrinterType type) async {
    try {
      final printer = _printers[type];
      await printer?.connection?.close();
      _printers[type] = PrinterConnection(type: type);
      print('🔵 Desconectado impresora ${type.name}');
    } catch (e) {
      print('🔴 Error desconectando impresora ${type.name}: $e');
    }
  }

  /// Desconecta todas las impresoras
  Future<void> disconnectAll() async {
    await disconnect(PrinterType.main);
  }

  /// Verifica si hay una impresora conectada del tipo especificado
  bool isConnected(PrinterType type) => _printers[type]?.isConnected ?? false;

  /// Verifica si hay alguna impresora conectada
  bool get hasAnyPrinterConnected => isConnected(PrinterType.main);

  /// Obtiene el dispositivo conectado del tipo especificado
  BluetoothDevice? getConnectedDevice(PrinterType type) => _printers[type]?.device;

  /// Obtiene el dispositivo conectado (para compatibilidad con código anterior)
  BluetoothDevice? get connectedDevice => getConnectedDevice(PrinterType.main);

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

  /// Imprime la factura de la orden en la impresora de cocina
  Future<bool> printOrderReceipt({
    required List<OrderItem> orderItems,
    required TableEntity table,
    required String waiterName,
    required String orderId,
    required DateTime orderTime,
  }) async {
    print('🔵 Iniciando impresión de orden. Estado de conexión: ${isConnected(PrinterType.main)}');
    
    if (!isConnected(PrinterType.main)) {
      print('🔴 No hay impresora conectada');
      return false;
    }

    try {
      print('🔵 Generando contenido de orden...');
      final receipt = _buildOrderReceipt(
        orderItems: orderItems,
        table: table,
        waiterName: waiterName,
        orderId: orderId,
        orderTime: orderTime,
      );

      print('🔵 Enviando datos a impresora...');
      final printer = _printers[PrinterType.main]!;
      
      if (printer.connection == null) {
        print('🔴 Conexión de impresora es null');
        return false;
      }

      printer.connection!.output.add(receipt);
      await printer.connection!.output.allSent;
      
      print('✅ Orden impresa en cocina exitosamente');
      return true;
    } catch (e) {
      print('🔴 Error imprimiendo orden en cocina: $e');
      return false;
    }
  }

  /// Imprime la factura del cliente
  Future<bool> printBill({
    required String orderId,
    required int tableNumber,
    required String waiterName,
    required List<dynamic> items,
    required double subtotal,
    required double tip,
    required double total,
    required int tipPercentage,
    required DateTime createdAt,
  }) async {
    if (!isConnected(PrinterType.main)) {
      print('🔴 No hay impresora conectada');
      return false;
    }

    try {
      final receipt = _buildBillReceipt(
        orderId: orderId,
        tableNumber: tableNumber,
        waiterName: waiterName,
        items: items,
        subtotal: subtotal,
        tip: tip,
        total: total,
        tipPercentage: tipPercentage,
        createdAt: createdAt,
      );

      final printer = _printers[PrinterType.main]!;
      printer.connection!.output.add(receipt);
      await printer.connection!.output.allSent;
      
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

  /// Construye el contenido de la factura del cliente
  Uint8List _buildBillReceipt({
    required String orderId,
    required int tableNumber,
    required String waiterName,
    required List<dynamic> items,
    required double subtotal,
    required double tip,
    required double total,
    required int tipPercentage,
    required DateTime createdAt,
  }) {
    List<int> bytes = [];

    // Comandos ESC/POS para impresora térmica
    const int ESC = 0x1B;
    const int GS = 0x1D;
    const int LF = 0x0A;

    // Inicializar impresora
    bytes.addAll([ESC, 0x40]); // ESC @ - Initialize printer

    // Configurar caracteres
    bytes.addAll([ESC, 0x74, 0x00]); // ESC t - Select character code table

    // Centrar encabezado
    bytes.addAll([ESC, 0x61, 0x01]); // ESC a - Center alignment
    bytes.addAll(utf8.encode('Restaurante Arroz Paisa Arrieros'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('JOHN FREDY NUÑEZ RENGIFO'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('NIT : 93.413.545-3'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('REGIMEN SIMPLIFICADO'));
    bytes.addAll([LF, LF]);

    // Alinear a la izquierda para información
    bytes.addAll([ESC, 0x61, 0x00]); // ESC a - Left alignment

    // Fecha y hora
    final formattedDate = _formatBillDateTime(createdAt);
    bytes.addAll(utf8.encode('REG  $formattedDate'));
    bytes.addAll([LF, LF]);

    // Items
    for (final item in items) {
      final quantity = item['quantity']?.toString() ?? '1';
      final productName = item['productName']?.toString() ?? '';
      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
      
      bytes.addAll(utf8.encode('$quantity  $productName.      ${_formatPrice(unitPrice)}'));
      bytes.addAll([LF]);
      bytes.addAll([LF]);
    }

    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('--------------------------------'));
    bytes.addAll([LF]);

    // SubTotal
    bytes.addAll(utf8.encode('SubTotal             ${_formatPrice(subtotal)}'));
    bytes.addAll([LF]);

    // Propina
    bytes.addAll(utf8.encode('Propina Voluntaria   ${_formatPrice(tip)}    '));
    //bytes.addAll([LF, LF]);

    // Línea separadora antes del total
    bytes.addAll(utf8.encode('--------------------------------'));
    bytes.addAll([LF]);

    // Total (en negrita y más grande)
    bytes.addAll([ESC, 0x45, 0x01]); // ESC E - Bold on
    bytes.addAll([ESC, 0x21, 0x30]); // ESC ! - Double width and height
    bytes.addAll(utf8.encode('TOTAL   ${_formatPrice(total)}')); 
    bytes.addAll([ESC, 0x21, 0x00]); // ESC ! - Normal size
    bytes.addAll([ESC, 0x45, 0x00]); // ESC E - Bold off
 

    // Línea separadora antes del total
    bytes.addAll(utf8.encode('--------------------------------'));
    bytes.addAll([LF]);

    // Pie de página
    bytes.addAll(utf8.encode('En este establecimiento sugerimos una propina del 10% sobre'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('el valor total del consumo. El cliente puede decidir si la'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('acepta, modificarla o rechazarla. En caso de no querer incluirla,'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('puede informarlo al momento de realizar el pago, conforme'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('a lo establecido en la Ley 1480 de 2011 y el Decreto 2438 de 2015.'));
    bytes.addAll([LF, LF]);

    // Centrar mensaje final
    bytes.addAll([ESC, 0x61, 0x01]); // ESC a - Center alignment
    bytes.addAll(utf8.encode('GRACIAS POR TU VISITA'));
    bytes.addAll([LF]);
    bytes.addAll(utf8.encode('ESPERAMOS VOLVERTE A VER PRONTO!'));
    bytes.addAll([LF, LF, LF]);

    // Cortar papel (si la impresora lo soporta)
    bytes.addAll([GS, 0x56, 0x00]); // GS V - Full cut

    return Uint8List.fromList(bytes);
  }

  String _formatPrice(double price) {
    final priceInt = price.toInt();
    final priceStr = priceInt.toString();
    
    if (priceStr.length <= 3) {
      return '\$$priceStr';
    }
    
    String formatted = '';
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = priceStr[i] + formatted;
      count++;
    }
    
    return '\$$formatted';
  }

  String _formatBillDateTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$year-$month-$day     $hour:$minute';
  }

  /// Formatea la fecha y hora para la orden de cocina
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
  Future<bool> printTestPage([PrinterType? printerType]) async {
    final type = printerType ?? PrinterType.main;
    
    if (!isConnected(type)) {
      print('🔴 No hay impresora ${type.name} conectada');
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
      bytes.addAll(utf8.encode('Impresora: ${type.name}'));
      bytes.addAll([LF]);
      bytes.addAll(utf8.encode('Goojprt PT210'));
      bytes.addAll([LF, LF, LF]);

      final printer = _printers[type]!;
      printer.connection!.output.add(Uint8List.fromList(bytes));
      await printer.connection!.output.allSent;
      
      print('✅ Página de prueba impresa en ${type.name}');
      return true;
    } catch (e) {
      print('🔴 Error en prueba de impresión ${type.name}: $e');
      return false;
    }
  }
}