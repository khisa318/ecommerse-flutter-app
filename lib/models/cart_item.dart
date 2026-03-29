import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final String? variantId; // New: link to specific variant
  int quantity;
  final Map<String, String> selectedAttributes;

  CartItem({
    required this.id,
    required this.product,
    this.variantId,
    this.quantity = 1,
    required this.selectedAttributes,
  });

  /// Get price based on selected variant or base product
  double get unitPrice {
    if (variantId != null) {
      final variant = product.variants.firstWhere((v) => v.id == variantId);
      return (variant.price ?? product.price);
    }
    return product.price;
  }

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    String? variantId,
    int? quantity,
    Map<String, String>? selectedAttributes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      selectedAttributes: selectedAttributes ?? this.selectedAttributes,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      variantId: json['variantId'],
      quantity: json['quantity'] ?? 1,
      selectedAttributes: Map<String, String>.from(json['selectedAttributes'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'variantId': variantId,
      'quantity': quantity,
      'selectedAttributes': selectedAttributes,
    };
  }
}
