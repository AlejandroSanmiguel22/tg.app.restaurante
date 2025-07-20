import '../../domain/repositories/login_repository.dart';
import '../datasources/login_datasource.dart';
import '../models/login_response_model.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginDatasource datasource;
  LoginRepositoryImpl(this.datasource);

  @override
  Future<LoginResponseModel> login({required String userName, required String password}) async {
    final response = await datasource.login(userName: userName, password: password);
    return LoginResponseModel.fromJson(response);
  }
} 