import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/table_entity.dart';

class TableCardWidget extends StatelessWidget {
  final TableEntity table;
  final VoidCallback onTap;

  const TableCardWidget({
    Key? key,
    required this.table,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Imagen de la mesa según su estado
            SvgPicture.asset(
              _getTableImage(),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            ),
            
            // Número de la mesa superpuesto
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getTableColor(),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${table.number}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getTableColor(),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTableImage() {
    if (table.isAvailable) {
      return 'assets/images/mesa_disponible.svg';
    } else if (table.isOccupied) {
      return 'assets/images/mesa_ocupada.svg';
    } else if (table.isAttended) {
      return 'assets/images/mesa_atendida.svg';
    } else {
      return 'assets/images/mesa_disponible.svg'; // Default
    }
  }

  Color _getTableColor() {
    if (table.isAvailable) {
      return Colors.grey;
    } else if (table.isOccupied) {
      return const Color(0xFFC83636); // Rojo
    } else if (table.isAttended) {
      return Colors.green;
    } else {
      return Colors.grey; // Default
    }
  }
}