import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/table_bloc.dart';
import '../../domain/entities/table_entity.dart';
import '../widgets/table_card_widget.dart';

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
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Selecciona una mesa disponible para hacer tu orden',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Leyenda de estados
                          Row(
                            children: [
                              _buildLegend('Disponible', Colors.grey),
                              const SizedBox(width: 16),
                              _buildLegend('Ocupada', const Color(0xFFC83636)),
                              const SizedBox(width: 16),
                              _buildLegend('Atendida', Colors.green),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      
                      // Grid de mesas
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 400, // Altura calculada
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

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  void _onTableTap(BuildContext context, TableEntity table) {
    if (table.isAvailable) {
      // Navegar a la pantalla de pedidos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesa ${table.number} seleccionada'),
          backgroundColor: Colors.green,
        ),
      );
      // TODO: Navegar a la pantalla de pedidos
      // Navigator.pushNamed(context, '/order', arguments: table);
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
}