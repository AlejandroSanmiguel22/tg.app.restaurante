import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/print_service.dart';
import '../../core/services/snackbar_service.dart';

class PrintersPage extends StatefulWidget {
  const PrintersPage({Key? key}) : super(key: key);

  @override
  State<PrintersPage> createState() => _PrintersPageState();
}

class _PrintersPageState extends State<PrintersPage> {
  final PrintService _printService = PrintService();
  List<BluetoothDevice> _printers = [];
  bool _isLoading = false;
  bool _isConnecting = false;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Verificar si ya hay impresora conectada
    setState(() {
      _connectedDevice = _printService.getConnectedDevice(PrinterType.main);
    });

    // Si no hay impresora conectada, intentar auto-conectar
    if (!_printService.isConnected(PrinterType.main)) {
      await _printService.autoConnect();
      setState(() {
        _connectedDevice = _printService.getConnectedDevice(PrinterType.main);
      });
    }
    
    await _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar permisos de Bluetooth
      if (await Permission.bluetoothConnect.isDenied) {
        await Permission.bluetoothConnect.request();
      }
      if (await Permission.bluetoothScan.isDenied) {
        await Permission.bluetoothScan.request();
      }
      if (await Permission.location.isDenied) {
        await Permission.location.request();
      }

      // Verificar si Bluetooth está habilitado
      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        SnackBarService.showError(
          context: context,
          title: 'Bluetooth deshabilitado',
          message: 'Por favor, habilita el Bluetooth para continuar',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final printers = await _printService.getAvailablePrinters();
      setState(() {
        _printers = printers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarService.showError(
        context: context,
        title: 'Error',
        message: 'Error al cargar impresoras: $e',
      );
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      final success = await _printService.connectToDevice(device, PrinterType.main);
      
      if (success) {
        setState(() {
          _connectedDevice = device;
        });
        
        SnackBarService.showSuccess(
          context: context,
          title: 'Conectado',
          message: 'Conectado a ${device.name}',
        );

        // Imprimir página de prueba
        await _printService.printTestPage(PrinterType.main);
      } else {
        SnackBarService.showError(
          context: context,
          title: 'Error de conexión',
          message: 'No se pudo conectar a la impresora',
        );
      }
    } catch (e) {
      SnackBarService.showError(
        context: context,
        title: 'Error',
        message: 'Error conectando: $e',
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnectPrinter() async {
    await _printService.disconnect(PrinterType.main);
    setState(() {
      _connectedDevice = null;
    });
    
    SnackBarService.showInfo(
      context: context,
      title: 'Desconectado',
      message: 'Impresora desconectada',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Banner superior
          Positioned(
            top: 37,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/banner.png', 
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
            ),
          ),
          // Icono de regreso en la esquina superior izquierda
          Positioned(
            top: 50,
            left: 1,
            child: Container(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back, 
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Contenido principal con margen superior para el banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 190), // Espacio para el banner
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Título y subtítulo
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Impresoras',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Conecta las impresoras:',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    
                    // Card principal
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 0.0, right: 4.0),
                        child: Card(
                          elevation: 20,
                          shadowColor: Colors.black.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Header con estado de conexión
                                _buildConnectionStatus(),
                                
                                const SizedBox(height: 16),
                                
                                // Lista de impresoras
                                Expanded(
                                  child: _buildPrintersList(),
                                ),
                                
                                // Botón de recargar
                                const SizedBox(height: 16),
                                _buildRefreshButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _connectedDevice != null 
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _connectedDevice != null 
              ? Colors.green
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _connectedDevice != null 
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
            color: _connectedDevice != null 
                ? Colors.green
                : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impresora Principal: ${_connectedDevice != null ? 'Conectada' : 'No conectada'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: _connectedDevice != null 
                        ? Colors.green[700]
                        : Colors.grey[700],
                  ),
                ),
                if (_connectedDevice != null)
                  Text(
                    _connectedDevice!.name ?? 'Dispositivo desconocido',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (_connectedDevice != null)
            TextButton(
              onPressed: () => _disconnectPrinter(),
              child: const Text(
                'Desconectar',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrintersList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC83636),
        ),
      );
    }

    if (_printers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.print_disabled,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron impresoras',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Asegúrate de que las impresoras estén\nemparejadas con el dispositivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _printers.length,
      itemBuilder: (context, index) {
        final printer = _printers[index];
        final isConnected = _connectedDevice?.address == printer.address;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected 
                      ? Colors.green
                      : Colors.grey.withOpacity(0.2),
                  width: isConnected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icono de impresora
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isConnected 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.print,
                      color: isConnected 
                          ? Colors.green
                          : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información de la impresora
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          printer.name ?? 'Dispositivo desconocido',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          printer.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (isConnected) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Conectada',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Botón de conectar
                  if (!isConnected)
                    ElevatedButton(
                      onPressed: _isConnecting 
                          ? null 
                          : () => _connectToPrinter(printer),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC83636),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: const Size(70, 30),
                          ),
                          child: _isConnecting
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Conectar',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _loadPrinters,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC83636),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, size: 18),
        label: Text(
          _isLoading ? 'Buscando...' : 'Buscar impresoras',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}