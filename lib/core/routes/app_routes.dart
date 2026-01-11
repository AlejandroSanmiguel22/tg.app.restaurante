import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/bloc/table_bloc.dart';
import '../dependencies/table_dependencies.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      
      case home:
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => TableDependencies.createTableBloc(_createDioClient()),
            child: const HomePage(),
          ),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Página no encontrada'),
            ),
          ),
        );
    }
  }

  /// Crear cliente Dio con configuración de timeout
  static Dio _createDioClient() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(minutes: 2);
    dio.options.receiveTimeout = const Duration(minutes: 2);
    dio.options.sendTimeout = const Duration(minutes: 2);
    return dio;
  }
}