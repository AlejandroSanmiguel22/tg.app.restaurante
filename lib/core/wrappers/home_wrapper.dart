import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/bloc/table_bloc.dart';
import '../../data/datasources/table_datasource.dart';
import '../../data/repositories/table_repository_impl.dart';
import '../services/auth_service.dart';

/// Wrapper para la HomePage que maneja la autenticación y dependencias
/// Esta clase debe ser usada después del login exitoso
class HomePageWrapper extends StatelessWidget {
  const HomePageWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data == true) {
          return BlocProvider(
            create: (context) {
              // Crear cliente Dio con configuración optimizada
              final dio = Dio();
              dio.options.connectTimeout = const Duration(minutes: 2);
              dio.options.receiveTimeout = const Duration(minutes: 2);
              dio.options.sendTimeout = const Duration(minutes: 2);
              
              // Crear dependencias
              final datasource = TableDatasourceImpl(dio);
              final repository = TableRepositoryImpl(datasource);
              
              // Crear y retornar TableBloc
              return TableBloc(repository);
            },
            child: const HomePage(),
          );
        } else {
          // Si no hay sesión válida, mostrar mensaje
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sesión no válida',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor, inicia sesión nuevamente.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implementar navegación al login
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC83636),
                    ),
                    child: const Text(
                      'Ir al Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
  
  Future<bool> _checkAuthStatus() async {
    try {
      final hasSession = await AuthService.hasActiveSession();
      final token = await AuthService.getToken();
      print('🔵 HomePageWrapper: Verificando sesión...');
      print('🔵 Tiene sesión activa: $hasSession');
      print('🔵 Token disponible: ${token != null ? "Sí" : "No"}');
      return hasSession;
    } catch (e) {
      print('❌ HomePageWrapper: Error al verificar sesión: $e');
      return false;
    }
  }
}

/// Ejemplo de AuthWrapper modificado para usar HomePage en lugar de DashboardPage
class AuthWrapperWithHome extends StatelessWidget {
  const AuthWrapperWithHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlocBase<dynamic>, dynamic>(
      builder: (context, state) {
        // Aquí deberías usar tu LoginBloc y sus estados
        // if (state is AuthenticatedFromSession || state is LoginSuccess) {
        //   return const HomePageWrapper();
        // }
        // return const LoginPage();
        
        // Por ahora, directamente mostramos la HomePage para demostración
        return const HomePageWrapper();
      },
    );
  }
}