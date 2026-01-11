import '../../domain/repositories/table_repository.dart';
import '../../domain/entities/table_entity.dart';
import '../datasources/table_datasource.dart';
import '../models/table_model.dart';

class TableRepositoryImpl implements TableRepository {
  final TableDatasource datasource;
  
  TableRepositoryImpl(this.datasource);

  @override
  Future<List<TableEntity>> getTables() async {
    final response = await datasource.getTables();
    final tablesResponse = TablesResponseModel.fromJson(response);
    return tablesResponse.data;
  }
}