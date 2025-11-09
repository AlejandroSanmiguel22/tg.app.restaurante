import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Servicio para mostrar SnackBars personalizados y reutilizables
class SnackBarService {
  
  /// Mostrar SnackBar de éxito
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _buildSnackBarContent(
          title: title,
          message: message,
          iconWidget: SvgPicture.asset(
            'assets/icons/check_info.svg',
            width: 28,
            height: 28,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8, // Sombra al SnackBar
      ),
    );
  }

  /// Mostrar SnackBar de error
  static void showError({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _buildSnackBarContentError(
          title: title,
          message: message,
          iconWidget: const Icon(
            Icons.error,
            color: Colors.white,
            size: 28,
          ),
        ),
        backgroundColor: const Color(0xFFC83636), // Rojo de tu app
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8, // Sombra al SnackBar
      ),
    );
  }

  /// Mostrar SnackBar de información
  static void showInfo({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _buildSnackBarContent(
          title: title,
          message: message,
          iconWidget: SvgPicture.asset(
            'assets/icons/check_info.svg',
            width: 28,
            height: 28,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF), 
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8, // Sombra al SnackBar
      ),
    );
  }

  /// Mostrar SnackBar de advertencia
  static void showWarning({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _buildSnackBarContent(
          title: title,
          message: message,
          iconWidget: const Icon(
            Icons.warning,
            color: Colors.orange,
            size: 28,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8, // Sombra al SnackBar
      ),
    );
  }

  /// Construir el contenido del SnackBar
  static Widget _buildSnackBarContent({
    required String title,
    required String message,
    required Widget iconWidget,
  }) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        // Ícono a la derecha
        const SizedBox(width: 12),
        iconWidget,
      ],
    );
  }

  /// Construir el contenido del SnackBar para errores (fondo rojo, texto blanco)
  static Widget _buildSnackBarContentError({
    required String title,
    required String message,
    required Widget iconWidget,
  }) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // Texto blanco para errores
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white, // Texto blanco para errores
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        // Ícono a la derecha
        const SizedBox(width: 12),
        iconWidget,
      ],
    );
  }
}