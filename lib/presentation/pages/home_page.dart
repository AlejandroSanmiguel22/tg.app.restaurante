import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../bloc/table_bloc.dart';
import '../bloc/login_bloc.dart';
import '../../domain/entities/table_entity.dart';
import '../widgets/table_card_widget.dart';
import 'order_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Cargar las mesas al inicializar la pantalla
    context.read<TableBloc>().add(LoadTables());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Banner superior
          Positioned(
            top: 37,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/banner.png', 
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
            ),
          ),
          // Icono de logout en la esquina superior izquierda
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              child: IconButton(
                icon: const Icon(
                  Icons.logout, 
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 24,
                ),
                onPressed: () => _showLogoutDialog(context),
              ),
            ),
          ),
          // Contenido principal con margen superior para el banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 190), // Espacio para el banner
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Título y subtítulo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Toma tu Orden',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Selecciona una mesa disponible para hacer tu orden',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Leyenda de estados
                          Row(
                            children: [
                              const SizedBox(width: 65),
                              _buildLegend('Disponible', 'assets/images/status1.svg'),
                              const SizedBox(width: 35),
                              const SizedBox(width: 35),
                              _buildLegend('Atendida', 'assets/images/status3.svg'),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      
                      // Grid de mesas en una Card con sombra mejorada
                      Container(
                        height: MediaQuery.of(context).size.height - 440, // Card más pequeña (era 400)
                        margin: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: Card(
                          elevation: 30, // Más sombra (era 12)
                          shadowColor: Colors.black.withOpacity(0.4), // Sombra más intensa
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 6.0), // Padding igual en todos los lados
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: BlocBuilder<TableBloc, TableState>(
                              builder: (context, state) {
                                if (state is TableLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFC83636),
                                    ),
                                  );
                                }
                                
                                if (state is TableError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          state.message,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.red,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            context.read<TableBloc>().add(LoadTables());
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFC83636),
                                          ),
                                          child: const Text(
                                            'Reintentar',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                if (state is TableLoaded) {
                                  return RefreshIndicator(
                                    onRefresh: () async {
                                      context.read<TableBloc>().add(RefreshTables());
                                    },
                                    child: GridView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 1.0,
                                      ),
                                      itemCount: state.tables.length,
                                      itemBuilder: (context, index) {
                                        final table = state.tables[index];
                                        return TableCardWidget(
                                          table: table,
                                          onTap: () {
                                            _onTableTap(context, table);
                                          },
                                        );
                                      },
                                    ),
                                  );
                                }
                                
                                return const Center(
                                  child: Text(
                                    'No hay mesas disponibles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, String svgPath) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          svgPath,
          width: 25,
          height: 25,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _onTableTap(BuildContext context, TableEntity table) {
    if (table.isAvailable) {
      // Navegar a la pantalla de pedidos
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderPage(table: table),
        ),
      );
    } else {
      // Mostrar mensaje de mesa no disponible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La mesa ${table.number} no está disponible'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC83636),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Mostrar mensaje de logout
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Has cerrado sesión correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Trigger logout
                context.read<LoginBloc>().add(LogoutPressed());
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}