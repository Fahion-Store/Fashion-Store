import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final String? selectedSize;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedSize,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? selectedSize,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'quantity': quantity,
      'selectedSize': selectedSize,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final productData = map['product'] as Map<String, dynamic>? ?? {};
    final productId = productData['id'] ?? '';
    return CartItem(
      id: map['id'] ?? '',
      product: Product.fromMap(productData, productId),
      quantity: map['quantity'] ?? 1,
      selectedSize: map['selectedSize'],
    );
  }
}