import '../repositories/login_repository.dart';
import '../../data/models/login_response_model.dart';

class LoginUseCase {
  final LoginRepository repository;
  LoginUseCase(this.repository);

  Future<LoginResponseModel> call({required String userName, required String password}) async {
    return await repository.login(userName: userName, password: password);
  }
} 