import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/models/login_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Estados
abstract class LoginState {}
class LoginInitial extends LoginState {}
class LoginLoading extends LoginState {}
class LoginSuccess extends LoginState {
  final LoginResponseModel response;
  LoginSuccess(this.response);
}
class LoginFailure extends LoginState {
  final String error;
  LoginFailure(this.error);
}

// Eventos
abstract class LoginEvent {}
class LoginButtonPressed extends LoginEvent {
  final String userName;
  final String password;
  LoginButtonPressed({required this.userName, required this.password});
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  LoginBloc(this.loginUseCase) : super(LoginInitial()) {
    on<LoginButtonPressed>((event, emit) async {
      emit(LoginLoading());
      try {
        final response = await loginUseCase(userName: event.userName, password: event.password);
        // Guardar token en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response.token);
        emit(LoginSuccess(response));
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });
  }
} 