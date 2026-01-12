import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../core/services/order_service.dart';
import '../../core/services/print_service.dart';
import '../../core/services/snackbar_service.dart';

class ManageOrderPage extends StatefulWidget {
  final TableEntity table;

  const ManageOrderPage({
    Key? key,
    required this.table,
  }) : super(key: key);

  @override
  State<ManageOrderPage> createState() => _ManageOrderPageState();
}

class _ManageOrderPageState extends State<ManageOrderPage> {
  final Dio _dio = Dio();
  late OrderService _orderService;
  final PrintService _printService = PrintService();
  
  OrderEntity? _currentOrder;
  bool _isLoading = false;
  bool _isUpdating = false;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadActiveOrder();
  }

  void _initializeServices() {
    _orderService = OrderService(_dio);
  }

  void _loadActiveOrder() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final order = await _orderService.getActiveOrderByTable(widget.table.id);
      setState(() {
        _currentOrder = order;
        _isLoading = false;
      });
      
      if (order != null) {
        print('🔵 Orden activa cargada: ${order.id}');
        print('🔵 Items en orden: ${order.items.length}');
        // Debug: verificar que las imágenes se estén cargando
        for (var item in order.items) {
          print('🔵 Item: ${item.product.name} - Imagen: ${item.product.imageUrl}');
        }
      } else {
        print('🔵 No hay orden activa para la mesa ${widget.table.number}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('🔴 Error al cargar orden activa: $e');
      SnackBarService.showError(
        context: context,
        title: 'Error al cargar orden',
        message: e.toString(),
      );
    }
  }

  String _formatPrice(double price) {
    final priceInt = price.toInt();
    final priceStr = priceInt.toString();
    
    if (priceStr.length <= 3) {
      return priceStr;
    }
    
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
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Contenido principal con margen superior para el banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 190),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Título y subtítulo
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Orden activa',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Selecciona',
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
                    ),
                    
                    // Card principal
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
                                // Número de mesa (sin barra de búsqueda)
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
                                    // Espacio vacío donde estaría la barra de búsqueda
                                    const Expanded(
                                      child: SizedBox(),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Lista de productos con scroll - ocupa el espacio restante
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: _buildOrderItemsList(),
                                  ),
                                ),
                                
                                // Área fija del resumen y botón
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Card del resumen (fija)
                                    _buildOrderSummaryCard(),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Botones de acción
                                    _buildActionButtons(),
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
    );
  }

  Widget _buildOrderItemsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC83636),
        ),
      );
    }
    
    if (_currentOrder == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay orden activa',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta mesa no tiene una orden en progreso',
              style: TextStyle(
                color: Colors.grey[500],
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadActiveOrder,
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
        ),
      );
    }

    return ListView.builder(
      itemCount: _currentOrder!.items.length,
      itemBuilder: (context, index) {
        final item = _currentOrder!.items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Imagen del producto - más grande y redonda como en la imagen
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.product.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: const Color(0xFFC83636),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('🔴 Error cargando imagen del producto: $error');
                            return const Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.product.description.isNotEmpty)
                      Text(
                        item.product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '\$ ${_formatPrice(item.totalPrice)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC83636),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              // Cantidad en un badge más visible
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFC83636),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
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
    if (_currentOrder == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
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
            SizedBox(width: 8),
            Text(
              '\$ 0',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            Spacer(),
            Text(
              'Total:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            SizedBox(width: 8),
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
          const Text(
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
            '\$ ${_formatPrice(_currentOrder!.subtotal)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
          ),
          const Spacer(),
          const Text(
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
            '\$ ${_formatPrice(_currentOrder!.total)}',
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Botón Factura
        Expanded(
          child: ElevatedButton(
            onPressed: (_currentOrder == null || _isUpdating) ? null : _generateInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_currentOrder == null || _isUpdating) ? Colors.grey[300] : const Color(0xFFC83636),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 2,
            ),
            child: _isUpdating 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Factura',
                        style: TextStyle(
                          color: (_currentOrder == null || _isUpdating) ? Colors.grey[600] : Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SvgPicture.asset(
                        'assets/icons/factura.svg',
                        width: 16,
                        height: 16,
                        color: (_currentOrder == null || _isUpdating) ? Colors.grey[600] : Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Botón Cerrar
        Expanded(
          child: ElevatedButton(
            onPressed: (_currentOrder == null || _isUpdating) ? null : _closeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_currentOrder == null || _isUpdating) ? Colors.grey[300] : const Color(0xFFC83636),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cerrar',
                  style: TextStyle(
                    color: (_currentOrder == null || _isUpdating) ? Colors.grey[600] : Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                SvgPicture.asset(
                  'assets/icons/send.svg',
                  width: 16,
                  height: 16,
                  color: (_currentOrder == null || _isUpdating) ? Colors.grey[600] : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _generateInvoice() async {
    if (_currentOrder == null) return;
    
    setState(() {
      _isUpdating = true;
    });

    try {
      // Verificar si hay impresora conectada
      if (!_printService.isConnected(PrinterType.main)) {
        SnackBarService.showError(
          context: context,
          title: 'Error de impresión',
          message: 'No hay impresora conectada. Ve a Configuración > Impresoras para conectar una.',
        );
        return;
      }

      // Generar factura en el servidor
      final billData = await _orderService.generateBillData(_currentOrder!.id);
      
      if (billData != null) {
        // Imprimir la factura
        final printSuccess = await _printService.printBill(
          orderId: billData['orderId'] ?? _currentOrder!.id,
          tableNumber: billData['tableNumber'] ?? widget.table.number,
          waiterName: billData['waiterName'] ?? 'Mesero',
          items: billData['items'] ?? [],
          subtotal: (billData['subtotal'] as num?)?.toDouble() ?? _currentOrder!.subtotal,
          tip: (billData['tip'] as num?)?.toDouble() ?? 0.0,
          total: (billData['total'] as num?)?.toDouble() ?? _currentOrder!.total,
          tipPercentage: billData['tipPercentage'] ?? 0,
          createdAt: billData['createdAt'] != null 
              ? DateTime.parse(billData['createdAt'])
              : DateTime.now(),
        );

        if (printSuccess) {
          SnackBarService.showSuccess(
            context: context,
            title: '¡Factura generada!',
            message: 'Factura generada e impresa exitosamente para la mesa ${widget.table.number}',
          );
        } else {
          SnackBarService.showWarning(
            context: context,
            title: 'Factura generada',
            message: 'Factura generada pero no se pudo imprimir. Verifica la conexión de la impresora.',
          );
        }
      } else {
        throw Exception('No se pudo obtener los datos de la factura');
      }
    } catch (e) {
      SnackBarService.showError(
        context: context,
        title: 'Error al generar factura',
        message: e.toString(),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _closeOrder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono y título
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC83636),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cerrar Pedido',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Estás seguro de que deseas cerrar el pedido de la mesa ${widget.table.number}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Información del total
                if (_currentOrder != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SubTotal:',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$ ${_formatPrice(_currentOrder!.subtotal)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC83636),
                              ),
                            ),
                            Text(
                              '\$ ${_formatPrice(_currentOrder!.total)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC83636),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const Text(
                  '¿Incluir propina del 10%?',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    // Botón Cancelar
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón Sin Propina
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _performCloseOrder(false); // Sin propina
                        },
                        child: const Text(
                          'Sin Propina',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón Con Propina
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC83636),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _performCloseOrder(true); // Con propina
                        },
                        child: const Text(
                          'Con Propina',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performCloseOrder(bool withTip) async {
    if (_currentOrder == null) return;
    
    setState(() {
      _isUpdating = true;
    });

    try {
      // Primero generar y obtener los datos de la factura con la propina incluida
      final billData = await _orderService.generateBillDataWithTip(_currentOrder!.id, withTip);
      
      if (billData != null) {
        // Cerrar la orden en el servidor
        final success = await _orderService.closeOrder(_currentOrder!.id, withTip);
        
        if (success) {
          // Verificar si hay impresora conectada
          if (_printService.isConnected(PrinterType.main)) {
            // Imprimir la factura final
            final printSuccess = await _printService.printBill(
              orderId: billData['orderId'] ?? _currentOrder!.id,
              tableNumber: billData['tableNumber'] ?? widget.table.number,
              waiterName: billData['waiterName'] ?? 'Mesero',
              items: billData['items'] ?? [],
              subtotal: (billData['subtotal'] as num?)?.toDouble() ?? _currentOrder!.subtotal,
              tip: (billData['tip'] as num?)?.toDouble() ?? 0.0,
              total: (billData['total'] as num?)?.toDouble() ?? _currentOrder!.total,
              tipPercentage: billData['tipPercentage'] ?? 0,
              createdAt: billData['createdAt'] != null 
                  ? DateTime.parse(billData['createdAt'])
                  : DateTime.now(),
            );

            if (printSuccess) {
              SnackBarService.showSuccess(
                context: context,
                title: '¡Pedido cerrado!',
                message: 'Pedido de la mesa ${widget.table.number} cerrado exitosamente${withTip ? ' con propina' : ' sin propina'}. Factura impresa.',
              );
            } else {
              SnackBarService.showSuccess(
                context: context,
                title: '¡Pedido cerrado!',
                message: 'Pedido de la mesa ${widget.table.number} cerrado exitosamente${withTip ? ' con propina' : ' sin propina'}. Error al imprimir factura.',
              );
            }
          } else {
            SnackBarService.showSuccess(
              context: context,
              title: '¡Pedido cerrado!',
              message: 'Pedido de la mesa ${widget.table.number} cerrado exitosamente${withTip ? ' con propina' : ' sin propina'}. No hay impresora de facturas conectada.',
            );
          }
          
          Navigator.of(context).pop(true); // Volver a la pantalla anterior con resultado exitoso
        } else {
          throw Exception('No se pudo cerrar el pedido');
        }
      } else {
        throw Exception('No se pudo obtener los datos de la factura');
      }
    } catch (e) {
      SnackBarService.showError(
        context: context,
        title: 'Error al cerrar pedido',
        message: e.toString(),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }
}