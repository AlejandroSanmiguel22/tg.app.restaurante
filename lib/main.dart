import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'data/datasources/login_datasource.dart';
import 'data/repositories/login_repository_impl.dart';
import 'domain/usecases/login_usecase.dart';
import 'presentation/bloc/login_bloc.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LoginBloc(
            LoginUseCase(
              LoginRepositoryImpl(
                LoginDatasourceImpl(Dio()),
              ),
            ),
          )..add(CheckAuthStatus()), // Verificar sesión al iniciar
        ),
      ],
      child: MaterialApp(
        title: 'TG Restaurante',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoggedOut) {
          // Si se hace logout, no necesitamos navegar porque el builder ya maneja esto
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          // Si hay sesión activa, ir a dashboard
          if (state is AuthenticatedFromSession || state is LoginSuccess) {
            return const DashboardPage();
          }
          
          // Para todos los demás casos (LoginInitial, LoginFailure, LoggedOut), mostrar login
          return const LoginPage();
        },
      ),
    );
  }
}

class BluetoothPrintTestPage extends StatefulWidget {
  const BluetoothPrintTestPage({Key? key}) : super(key: key);

  @override
  State<BluetoothPrintTestPage> createState() => _BluetoothPrintTestPageState();
}

class _BluetoothPrintTestPageState extends State<BluetoothPrintTestPage> {
  List<BluetoothDevice> devices = [];
  List<BluetoothDevice> selectedDevices = [];
  Map<String, BluetoothConnection> connections = {};
  Map<String, bool> connectionStatus = {};
  String _message = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Solicitar permisos de ubicación (necesarios para Bluetooth en Android)
    await Permission.location.request();
    await Permission.locationWhenInUse.request();
    
    // Solicitar permisos de Bluetooth
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    
    // Inicializar Bluetooth después de solicitar permisos
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      final List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        devices = bondedDevices;
      });
    } catch (e) {
      print('Error al obtener dispositivos: $e');
    }
  }

  Future<void> _refreshDevices() async {
    await _initBluetooth();
  }

  void _toggleDeviceSelection(BluetoothDevice device) {
    setState(() {
      if (selectedDevices.contains(device)) {
        selectedDevices.remove(device);
        // Desconectar si estaba conectado
        _disconnectDevice(device);
      } else {
        selectedDevices.add(device);
      }
    });
  }

  void _connectAllSelected() async {
    for (BluetoothDevice device in selectedDevices) {
      if (!connectionStatus.containsKey(device.address) || !connectionStatus[device.address]!) {
        await _connectDevice(device);
      }
    }
  }

  void _disconnectAll() async {
    for (BluetoothDevice device in selectedDevices) {
      await _disconnectDevice(device);
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    try {
      // Intentar conexión con retry
      BluetoothConnection? connection;
      int retryCount = 0;
      const maxRetries = 2;
      
      while (retryCount < maxRetries) {
        try {
          connection = await BluetoothConnection.toAddress(device.address);
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw e;
          }
          await Future.delayed(Duration(seconds: 1));
        }
      }
      
      if (connection != null) {
        connections[device.address] = connection;
        setState(() {
          connectionStatus[device.address] = connection!.isConnected;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conectado a ${device.name ?? device.address}')),
        );
      }
    } catch (e) {
      print('Error al conectar a ${device.name}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar a ${device.name}: $e')),
      );
    }
  }

  Future<void> _disconnectDevice(BluetoothDevice device) async {
    try {
      final connection = connections[device.address];
      if (connection != null) {
        await connection.close();
        connections.remove(device.address);
        setState(() {
          connectionStatus[device.address] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Desconectado de ${device.name ?? device.address}')),
        );
      }
    } catch (e) {
      print('Error al desconectar de ${device.name}: $e');
    }
  }

  void _print() async {
    if (_message.isNotEmpty && connections.isNotEmpty) {
      try {
        // Comandos ESC/POS básicos para impresora térmica
        List<int> bytes = [];
        
        // ESC @ - Inicializar impresora
        bytes.addAll([0x1B, 0x40]);
        
        // ESC ! - Configurar fuente (0x00 = normal, 0x01 = bold)
        bytes.addAll([0x1B, 0x21, 0x00]);
        
        // ESC a - Alineación (0x01 = centro)
        bytes.addAll([0x1B, 0x61, 0x01]);
        
        // Texto
        bytes.addAll(_message.codeUnits);
        
        // LF - Nueva línea
        bytes.add(0x0A);
        bytes.add(0x0A);
        
        // GS V - Cortar papel
        bytes.addAll([0x1D, 0x56, 0x00]);
        
        // Enviar a todas las impresoras conectadas
        List<Future<void>> printTasks = [];
        
        for (var entry in connections.entries) {
          if (entry.value.isConnected) {
            printTasks.add(_sendToPrinter(entry.value, bytes));
          }
        }
        
        await Future.wait(printTasks);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impresión exitosa en ${connections.length} impresora(s)')),
        );
      } catch (e) {
        print('Error al imprimir: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al imprimir: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay impresoras conectadas o mensaje vacío')),
      );
    }
  }

  Future<void> _sendToPrinter(BluetoothConnection connection, List<int> bytes) async {
    connection.output.add(Uint8List.fromList(bytes));
    await connection.output.allSent;
  }

  bool get _hasConnectedPrinters => connections.values.any((conn) => conn.isConnected);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba Impresora Bluetooth')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mensaje a imprimir:'),
            TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _message = value),
              decoration: const InputDecoration(hintText: 'Escribe tu mensaje'),
            ),
            const SizedBox(height: 16),
            const Text('Selecciona las impresoras:'),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isSelected = selectedDevices.contains(device);
                  final isConnected = connectionStatus[device.address] ?? false;
                  
                  return ListTile(
                    title: Text(device.name ?? device.address),
                    subtitle: Text(device.address),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isConnected)
                          const Icon(Icons.bluetooth_connected, color: Colors.green)
                        else if (isSelected)
                          const Icon(Icons.bluetooth, color: Colors.blue),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleDeviceSelection(device),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (devices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'No se encontraron dispositivos. Asegúrate de haber emparejado las impresoras.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: selectedDevices.isNotEmpty ? _connectAllSelected : null,
                  child: const Text('Conectar Seleccionadas'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: connections.isNotEmpty ? _disconnectAll : null,
                  child: const Text('Desconectar Todas'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _refreshDevices,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refrescar dispositivos',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _hasConnectedPrinters && _message.isNotEmpty ? _print : null,
                icon: const Icon(Icons.print),
                label: Text('Imprimir en ${connections.length} impresora(s)'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Estado: ${connections.length} impresora(s) conectada(s)'),
            if (connections.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Impresoras conectadas:'),
              ...connections.entries.map((entry) {
                final device = devices.firstWhere(
                  (d) => d.address == entry.key,
                  orElse: () => BluetoothDevice(address: entry.key, name: 'Desconocido'),
                );
                return Text('• ${device.name ?? device.address}');
              }),
            ],
          ],
        ),
      ),
    );
  }
}

