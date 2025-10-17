// Archivo de configuración de dependencias para las mesas
import 'package:dio/dio.dart';
import '../../data/datasources/table_datasource.dart';
import '../../data/repositories/table_repository_impl.dart';
import '../../domain/repositories/table_repository.dart';
import '../../presentation/bloc/table_bloc.dart';

class TableDependencies {
  static TableBloc createTableBloc(Dio dio) {
    final datasource = TableDatasourceImpl(dio);
    final repository = TableRepositoryImpl(datasource);
    return TableBloc(repository);
  }
}