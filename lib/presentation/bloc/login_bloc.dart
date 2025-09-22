import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/models/login_response_model.dart';
import '../../core/services/auth_service.dart';

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
class AuthenticatedFromSession extends LoginState {
  final Map<String, String?> userData;
  AuthenticatedFromSession(this.userData);
}
class LoggedOut extends LoginState {}

// Eventos
abstract class LoginEvent {}

class LoginButtonPressed extends LoginEvent {
  final String userName;
  final String password;
  LoginButtonPressed({required this.userName, required this.password});
}

class CheckAuthStatus extends LoginEvent {}

class LogoutPressed extends LoginEvent {}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  
  LoginBloc(this.loginUseCase) : super(LoginInitial()) {
    // Evento de login
    on<LoginButtonPressed>((event, emit) async {
      print('🟡 LoginBloc: Iniciando proceso de login');
      print('🟡 Usuario: ${event.userName}');
      
      emit(LoginLoading());
      try {
        print('🟡 LoginBloc: Llamando a usecase...');
        final response = await loginUseCase(userName: event.userName, password: event.password);
        
        print('🟢 LoginBloc: Respuesta recibida del usecase');
        print('🟢 Token: ${response.token}');
        print('🟢 Usuario: ${response.user.userName}');
        
        // Guardar sesión usando AuthService
        await AuthService.saveSession(
          token: response.token,
          userId: response.user.id,
          userName: response.user.userName,
          userRole: response.user.role,
        );
        
        print('🟢 LoginBloc: Sesión guardada, emitiendo LoginSuccess');
        emit(LoginSuccess(response));
      } catch (e) {
        print('🔴 LoginBloc: Error en login');
        print('🔴 Error: $e');
        emit(LoginFailure(e.toString()));
      }
    });
    
    // Evento para verificar sesión existente
    on<CheckAuthStatus>((event, emit) async {
      try {
        final hasSession = await AuthService.hasActiveSession();
        if (hasSession) {
          final userData = await AuthService.getUserData();
          emit(AuthenticatedFromSession(userData));
        } else {
          emit(LoginInitial());
        }
      } catch (e) {
        emit(LoginInitial());
      }
    });
    
    // Evento de logout
    on<LogoutPressed>((event, emit) async {
      try {
        await AuthService.clearSession();
        emit(LoggedOut());
      } catch (e) {
        emit(LoginFailure('Error al cerrar sesión: ${e.toString()}'));
      }
    });
  }
} 