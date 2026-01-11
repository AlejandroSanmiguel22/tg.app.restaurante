import 'product_entity.dart';

class OrderItem {
  final String productId;
  final Product product;
  final int quantity;
  final String? notes;
  final double unitPrice;

  OrderItem({
    required this.productId,
    required this.product,
    required this.quantity,
    this.notes,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItem.fromProduct(Product product, {int quantity = 1, String? notes}) {
    return OrderItem(
      productId: product.id,
      product: product,
      quantity: quantity,
      notes: notes,
      unitPrice: product.price,
    );
  }

  factory OrderItem.fromOrderJson(Map<String, dynamic> json) {
    // Crear un producto básico con la información disponible
    final product = Product(
      id: json['productId'] ?? '',
      name: json['productName'] ?? '',
      description: '',
      price: (json['unitPrice'] ?? 0).toDouble(),
      imageUrl: json['productImage'], // Ahora incluimos la imagen del producto
      category: '',
    );

    return OrderItem(
      productId: json['productId'] ?? '',
      product: product,
      quantity: json['quantity'] ?? 0,
      notes: json['notes'],
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'notes': notes,
    };
  }

  OrderItem copyWith({
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      productId: productId,
      product: product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      unitPrice: unitPrice,
    );
  }
}
