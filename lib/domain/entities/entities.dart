/// Domain Entities - Business Logic Models
class Product {
  final int id;
  final String title;
  final String description;
  final int price; // in cents
  final int stock;
  final int categoryId;
  final double discountPercentage;
  final bool isActive;
  final DateTime createdAt;
  final String imageUrl;
  final List<String> colors;
  final List<String> storageOptions;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.discountPercentage,
    required this.isActive,
    required this.createdAt,
    required this.imageUrl,
    required this.colors,
    required this.storageOptions,
  });

  // Computed properties
  bool get isOnSale => discountPercentage > 0;
  bool get isInStock => stock > 0;
  
  int get discountedPrice {
    final discounted = price - (price * discountPercentage / 100).toInt();
    return discounted.toInt();
  }

  double get rating => 4.5; // TODO: Calculate from reviews
}

class Category {
  final int id;
  final String name;
  final int? parentId;
  final bool isActive;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.isActive,
    required this.createdAt,
  });
}

class Order {
  final int id;
  final String userId;
  final int totalPrice; // in cents
  final String status; // pending, processing, shipped, delivered, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final int priceAtPurchase; // in cents

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
  });

  int get subtotal => priceAtPurchase * quantity;
}

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? address;
  final String role; // customer, admin
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.address,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';
}

class Review {
  final int id;
  final int productId;
  final String userId;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });
}

class Address {
  final String id;
  final String userId;
  final String fullAddress;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.userId,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });
}
