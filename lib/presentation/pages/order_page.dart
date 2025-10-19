import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../core/services/product_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/auth_service.dart';

class OrderPage extends StatefulWidget {
  final TableEntity table;
  
  const OrderPage({Key? key, required this.table}) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  final FocusNode _searchFocusNode = FocusNode();
  
  late ProductService _productService;
  late OrderService _orderService;
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<OrderItem> _cartItems = [];
  bool _isLoading = false;
  bool _isCreatingOrder = false;
  bool _showSearchDropdown = false;
  

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadProducts();
    
    // Listener para ocultar el dropdown cuando se pierde el foco
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          _showSearchDropdown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _productService = ProductService(_dio);
    _orderService = OrderService(_dio);
  }

  void _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
      print('🔵 Productos cargados: ${products.length}');
      for (var product in products) {
        print('🔵 Producto: ${product.name} - \$${product.price}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('🔴 Error al cargar productos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = [];
        _showSearchDropdown = false;
      } else {
        _filteredProducts = _products.where((product) =>
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase())
        ).toList();
        _showSearchDropdown = _filteredProducts.isNotEmpty;
      }
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.productId == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
          quantity: _cartItems[existingIndex].quantity + 1
        );
      } else {
        _cartItems.add(OrderItem.fromProduct(product));
      }
      // Limpiar búsqueda y ocultar dropdown
      _searchController.clear();
      _showSearchDropdown = false;
      _searchFocusNode.unfocus();
    });
  }

  Widget _buildSearchDropdown() {
    if (!_showSearchDropdown || _filteredProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredProducts.length > 5 ? 5 : _filteredProducts.length, // Máximo 5 elementos
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: index < _filteredProducts.length - 1 ? 1 : 0,
                ),
              ),
            ),
            child: ListTile(
              dense: true,
              title: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: GestureDetector(
                onTap: () => _addToCart(product),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC83636),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              onTap: () => _addToCart(product),
            ),
          );
        },
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = _cartItems[index].copyWith(quantity: newQuantity);
      }
    });
  }

  double get _subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get _total {
    const double tipPercentage = 0.03; // 3% de propina
    return _subtotal * (1 + tipPercentage);
  }

  String _formatPrice(double price) {
    // Formatear precio con separador de miles
    final priceInt = price.toInt();
    final priceStr = priceInt.toString();
    
    if (priceStr.length <= 3) {
      return priceStr;
    }
    
    // Agregar puntos como separadores de miles
    String formatted = '';
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = priceStr[i] + formatted;
      count++;
    }
    
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Ocultar dropdown y quitar foco cuando se toque fuera
        FocusScope.of(context).unfocus();
        setState(() {
          _showSearchDropdown = false;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false, // Evita que el scaffold se redimensione con el teclado
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
          // Icono de regreso en la esquina superior izquierda
          Positioned(
            top: 50,
            left: 1,
            child: Container(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back, 
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Contenido principal con margen superior para el banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 190), // Espacio para el banner
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Título y subtítulo
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Realiza tu Pedido',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selecciona los productos que deseas agregar a tu pedido',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    
                    // Card principal - sin scroll, altura fija
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 0.0, right: 4.0),
                        child: Card(
                          elevation: 20,
                          shadowColor: Colors.black.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Barra de búsqueda y filtro (fija)
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Número de mesa
                                        SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SvgPicture.asset(
                                            'assets/images/mesa_disponible.svg',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.contain,
                                            ),
                                            Text(
                                            '${widget.table.number}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                            ),
                                          ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Barra de búsqueda
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 12),
                                                SvgPicture.asset(
                                                  'assets/icons/search.svg',
                                                  width: 16,
                                                  height: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: TextField(
                                                    controller: _searchController,
                                                    focusNode: _searchFocusNode,
                                                    onChanged: _filterProducts,
                                                    decoration: const InputDecoration(
                                                      hintText: 'Buscar',
                                                      border: InputBorder.none,
                                                      hintStyle: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Botón de filtro
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: SvgPicture.asset(
                                              'assets/icons/filter.svg',
                                              width: 16,
                                              height: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Dropdown de búsqueda
                                    _buildSearchDropdown(),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Lista de productos con scroll (solo esta parte) - ocupa el espacio restante
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: _buildSelectedProductsList(),
                                  ),
                                ),
                                
                                // Área fija del resumen y botón (no afectada por el teclado)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Card del resumen (fija)
                                    _buildOrderSummaryCard(),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Botón de enviar separado (fijo)
                                    _buildSendButton(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSelectedProductsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC83636),
        ),
      );
    }
    
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _products.isEmpty ? 'No hay productos disponibles' : 'Busca productos para agregar al pedido',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
            ),
            if (_products.isEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC83636),
                ),
                child: const Text(
                  'Recargar',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              // Imagen del producto - más pequeña y cuadrada
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.product.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$ ${_formatPrice(item.product.price)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC83636),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              // Contador de cantidad
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _updateQuantity(index, item.quantity - 1),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.remove, size: 18),
                    ),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _updateQuantity(index, item.quantity + 1),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC83636),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Botón de eliminar - icono de basura rojo
              GestureDetector(
                onTap: () => _removeFromCart(index),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red[600],
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderSummaryCard() {
    // Si no hay productos, mostrar un resumen vacío
    if (_cartItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Text(
              'SubTotal:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$ 0',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Text(
              'Total:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$ 0',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'SubTotal:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$ ${_formatPrice(_subtotal)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            'Total:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$ ${_formatPrice(_total)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _cartItems.isEmpty || _isCreatingOrder ? null : _createOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: _cartItems.isEmpty ? Colors.grey[300] : const Color(0xFFC83636),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isCreatingOrder 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enviar',
                    style: TextStyle(
                      color: _cartItems.isEmpty ? Colors.grey[600] : Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.send,
                    color: _cartItems.isEmpty ? Colors.grey[600] : Colors.white,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  void _createOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega productos al pedido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      // Obtener datos del usuario para waiterId
      final userData = await AuthService.getUserData();
      final waiterId = userData['userId'];
      
      if (waiterId == null) {
        throw Exception('No se pudo obtener el ID del mesero');
      }

      // Crear la orden (enviamos null en notas)
      final success = await _orderService.createOrder(
        tableId: widget.table.id,
        waiterId: waiterId,
        items: _cartItems,
        notes: null,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido creado exitosamente para mesa ${widget.table.number}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('No se pudo crear el pedido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }
}