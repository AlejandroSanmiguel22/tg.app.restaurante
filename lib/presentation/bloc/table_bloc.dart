import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/repositories/table_repository.dart';

// Estados
abstract class TableState {}

class TableInitial extends TableState {}

class TableLoading extends TableState {}

class TableLoaded extends TableState {
  final List<TableEntity> tables;
  
  TableLoaded(this.tables);
}

class TableError extends TableState {
  final String message;
  
  TableError(this.message);
}

// Eventos
abstract class TableEvent {}

class LoadTables extends TableEvent {}

class RefreshTables extends TableEvent {}

// BLoC
class TableBloc extends Bloc<TableEvent, TableState> {
  final TableRepository repository;
  
  TableBloc(this.repository) : super(TableInitial()) {
    on<LoadTables>((event, emit) async {
      print('🟡 TableBloc: Cargando mesas...');
      
      emit(TableLoading());
      try {
        final tables = await repository.getTables();
        print('✅ TableBloc: Mesas cargadas exitosamente. Total: ${tables.length}');
        emit(TableLoaded(tables));
      } catch (e) {
        print('❌ TableBloc: Error al cargar mesas: $e');
        
        String errorMessage = 'Error al cargar las mesas';
        if (e is DioException) {
          switch (e.response?.statusCode) {
            case 401:
              errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
              break;
            case 404:
              errorMessage = 'Servicio no disponible. Contacta al administrador.';
              break;
            case 500:
              errorMessage = 'Error del servidor. Intenta más tarde.';
              break;
            default:
              errorMessage = 'Error de conexión: ${e.message}';
          }
        }
        
        emit(TableError(errorMessage));
      }
    });

    on<RefreshTables>((event, emit) async {
      print('🟡 TableBloc: Refrescando mesas...');
      
      try {
        final tables = await repository.getTables();
        print('✅ TableBloc: Mesas refrescadas exitosamente. Total: ${tables.length}');
        emit(TableLoaded(tables));
      } catch (e) {
        print('❌ TableBloc: Error al refrescar mesas: $e');
        
        String errorMessage = 'Error al refrescar las mesas';
        if (e is DioException) {
          switch (e.response?.statusCode) {
            case 401:
              errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
              break;
            case 404:
              errorMessage = 'Servicio no disponible. Contacta al administrador.';
              break;
            case 500:
              errorMessage = 'Error del servidor. Intenta más tarde.';
              break;
            default:
              errorMessage = 'Error de conexión: ${e.message}';
          }
        }
        
        emit(TableError(errorMessage));
      }
    });
  }
}