import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;
  String selectedColor;
  String selectedStorage;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    required this.selectedColor,
    required this.selectedStorage,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? selectedColor,
    String? selectedStorage,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedStorage: selectedStorage ?? this.selectedStorage,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      selectedColor: json['selectedColor'],
      selectedStorage: json['selectedStorage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedStorage': selectedStorage,
    };
  }
}
