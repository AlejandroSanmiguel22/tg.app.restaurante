import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../bloc/login_bloc.dart';
import 'dashboard_page.dart';
import '../../core/services/snackbar_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Ocultar teclado al tocar fuera
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false, // Evita que el scaffold se redimensione con el teclado
        body: Stack(
          children: [
            Positioned(
              top: 37,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/logo.png', 
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 75.0),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.30),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Campo de usuario
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: TextField(
                        controller: _userController,
                        enabled: true,
                        style: const TextStyle(fontFamily: 'Poppins'),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(
                              'assets/icons/mail.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          labelText: 'Nombre de Usuario',
                          labelStyle: const TextStyle(
                            color: Color(0xFF7C838A),
                            fontFamily: 'Poppins',
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de contraseña
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        enabled: true,
                        obscureText: _obscureText,
                        style: const TextStyle(fontFamily: 'Poppins'),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(
                              'assets/icons/password.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: SvgPicture.asset(
                              _obscureText
                                  ? 'assets/icons/eye-closed.svg'
                                  : 'assets/icons/eye.svg',
                              width: 20,
                              height: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          labelText: 'Contraseña',
                          labelStyle: const TextStyle(
                            color: Color(0xFF7C838A),
                            fontFamily: 'Poppins',
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Enlace de contraseña olvidada
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          SnackBarService.showInfo(
                            context: context,
                            title: 'Ups, lamentamos esto.',
                            message: 'Comunicate con tu Jefe, el es el unico que te puede proporciona la contraseña o generar una nueva.',
                          );
                        },
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Botón de iniciar sesión
                    BlocConsumer<LoginBloc, LoginState>(
                      listener: (context, state) {
                        if (state is LoginFailure) {
                          SnackBarService.showError(
                            context: context,
                            title: 'Error de Autenticación',
                            message: "Porfavor, verifica tus credenciales",
                          );
                        }
                        if (state is LoginSuccess) {
                          SnackBarService.showSuccess(
                            context: context,
                            title: '¡Bienvenido!',
                            message: 'Has iniciado sesión correctamente',
                          );
                          // La navegación se maneja automáticamente por AuthWrapper
                        }
                      },
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC83636),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 5,
                            ),
                            onPressed: state is LoginLoading
                                ? null
                                : () {
                                    BlocProvider.of<LoginBloc>(context).add(
                                      LoginButtonPressed(
                                        userName: _userController.text,
                                        password: _passwordController.text,
                                      ),
                                    );
                                  },
                            child: state is LoginLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Iniciar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
