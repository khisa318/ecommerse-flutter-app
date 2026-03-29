/// Data Transfer Objects (DTOs) - Maps Supabase JSON to Dart objects
import '../../domain/entities/entities.dart';

class ProductDTO {
  final int id;
  final String title;
  final String description;
  final int price;
  final int stock_quantity;
  final int category_id;
  final double? discount_percentage;
  final bool is_active;
  final DateTime created_at;
  final List<String>? images;
  final List<ProductVariantDTO>? variants;

  ProductDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.stock_quantity,
    required this.category_id,
    this.discount_percentage,
    required this.is_active,
    required this.created_at,
    this.images,
    this.variants,
  });

  /// Convert from JSON (Supabase response)
  factory ProductDTO.fromJson(Map<String, dynamic> json) {
    try {
      final variantsJson = json['variants'] as List<dynamic>?;
      final variants = variantsJson
          ?.map((v) => ProductVariantDTO.fromJson(v as Map<String, dynamic>))
          .toList();

      return ProductDTO(
        id: _asInt(json['id']),
        title: (json['title'] ?? 'Untitled Product').toString(),
        description: (json['description'] ?? '').toString(),
        price: _asInt(json['price']),
        stock_quantity: _asInt(json['stock_quantity']),
        category_id: _asInt(json['category_id']),
        discount_percentage: _asDoubleOrNull(json['discount_percentage']),
        is_active: _asBool(json['is_active']),
        created_at: _asDateTime(json['created_at']),
        images:
            json['images'] != null ? List<String>.from(json['images']) : null,
        variants: variants,
      );
    } catch (e) {
      print('   ❌ ProductDTO parsing error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'stock_quantity': stock_quantity,
      'category_id': category_id,
      'discount_percentage': discount_percentage,
      'is_active': is_active,
      'images': images,
    };
  }

  Product toEntity({
    required String imageUrl,
    required List<String> images,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id,
      title: title,
      description: description,
      price: price,
      stock: stock_quantity,
      categoryId: category_id,
      discountPercentage: discount_percentage ?? 0,
      isActive: is_active,
      createdAt: created_at,
      imageUrl: imageUrl,
      images: images,
      variants:
          variants ?? this.variants?.map((v) => v.toEntity()).toList() ?? [],
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value == null || value.toString().isEmpty) {
      return DateTime.now();
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class ProductVariantDTO {
  final String id;
  final int price;
  final int stock;
  final String? image_url;
  final Map<String, String> attributes;

  ProductVariantDTO({
    required this.id,
    required this.price,
    required this.stock,
    this.image_url,
    required this.attributes,
  });

  factory ProductVariantDTO.fromJson(Map<String, dynamic> json) {
    return ProductVariantDTO(
      id: json['id'].toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      image_url: json['image_url'] as String?,
      attributes: Map<String, String>.from(json['attributes'] ?? {}),
    );
  }

  ProductVariant toEntity() {
    return ProductVariant(
      id: id,
      price: price,
      stock: stock,
      imageUrl: image_url,
      attributes: attributes,
    );
  }
}

class CategoryDTO {
  final int id;
  final String name;
  final int? parent_id;
  final bool is_active;
  final DateTime created_at;

  CategoryDTO({
    required this.id,
    required this.name,
    this.parent_id,
    required this.is_active,
    required this.created_at,
  });

  factory CategoryDTO.fromJson(Map<String, dynamic> json) {
    return CategoryDTO(
      id: json['id'] as int,
      name: json['name'] as String,
      parent_id: json['parent_id'] as int?,
      is_active: json['is_active'] as bool? ?? true,
      created_at: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parent_id': parent_id,
      'is_active': is_active,
    };
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      parentId: parent_id,
      isActive: is_active,
      createdAt: created_at,
    );
  }
}

class OrderDTO {
  final int id;
  final String user_id;
  final int total_price;
  final String status;
  final DateTime created_at;
  final DateTime updated_at;

  OrderDTO({
    required this.id,
    required this.user_id,
    required this.total_price,
    required this.status,
    required this.created_at,
    required this.updated_at,
  });

  factory OrderDTO.fromJson(Map<String, dynamic> json) {
    return OrderDTO(
      id: json['id'] as int,
      user_id: json['user_id'] as String,
      total_price: json['total_price'] as int,
      status: json['status'] as String,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'total_price': total_price,
      'status': status,
    };
  }

  Order toEntity({required List<OrderItem> items}) {
    return Order(
      id: id,
      userId: user_id,
      totalPrice: total_price,
      status: status,
      createdAt: created_at,
      updatedAt: updated_at,
      items: items,
    );
  }
}

class OrderItemDTO {
  final int id;
  final int order_id;
  final int product_id;
  final int quantity;
  final int price_at_purchase;

  OrderItemDTO({
    required this.id,
    required this.order_id,
    required this.product_id,
    required this.quantity,
    required this.price_at_purchase,
  });

  factory OrderItemDTO.fromJson(Map<String, dynamic> json) {
    return OrderItemDTO(
      id: json['id'] as int,
      order_id: json['order_id'] as int,
      product_id: json['product_id'] as int,
      quantity: json['quantity'] as int,
      price_at_purchase: json['price_at_purchase'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': order_id,
      'product_id': product_id,
      'quantity': quantity,
      'price_at_purchase': price_at_purchase,
    };
  }

  OrderItem toEntity() {
    return OrderItem(
      id: id,
      orderId: order_id,
      productId: product_id,
      quantity: quantity,
      priceAtPurchase: price_at_purchase,
    );
  }
}

class UserProfileDTO {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? address;
  final String role;
  final DateTime created_at;
  final DateTime updated_at;

  UserProfileDTO({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.address,
    required this.role,
    required this.created_at,
    required this.updated_at,
  });

  factory UserProfileDTO.fromJson(Map<String, dynamic> json) {
    return UserProfileDTO(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      role: json['role'] as String? ?? 'customer',
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'role': role,
    };
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: email,
      name: name,
      phone: phone,
      address: address,
      role: role,
      createdAt: created_at,
      updatedAt: updated_at,
    );
  }
}

class ReviewDTO {
  final int id;
  final int product_id;
  final String user_id;
  final int rating;
  final String? comment;
  final DateTime created_at;
  final DateTime updated_at;

  ReviewDTO({
    required this.id,
    required this.product_id,
    required this.user_id,
    required this.rating,
    this.comment,
    required this.created_at,
    required this.updated_at,
  });

  factory ReviewDTO.fromJson(Map<String, dynamic> json) {
    return ReviewDTO(
      id: json['id'] as int,
      product_id: json['product_id'] as int,
      user_id: json['user_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': product_id,
      'user_id': user_id,
      'rating': rating,
      'comment': comment,
    };
  }

  Review toEntity() {
    return Review(
      id: id,
      productId: product_id,
      userId: user_id,
      rating: rating,
      comment: comment,
      createdAt: created_at,
      updatedAt: updated_at,
    );
  }
}

class AddressDTO {
  final String id;
  final String user_id;
  final String full_address;
  final String city;
  final String state;
  final String zip_code;
  final String phone;
  final bool is_default;
  final DateTime created_at;
  final DateTime updated_at;

  AddressDTO({
    required this.id,
    required this.user_id,
    required this.full_address,
    required this.city,
    required this.state,
    required this.zip_code,
    required this.phone,
    required this.is_default,
    required this.created_at,
    required this.updated_at,
  });

  factory AddressDTO.fromJson(Map<String, dynamic> json) {
    return AddressDTO(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      full_address: json['full_address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zip_code: json['zip_code'] as String,
      phone: json['phone'] as String,
      is_default: json['is_default'] as bool? ?? false,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'full_address': full_address,
      'city': city,
      'state': state,
      'zip_code': zip_code,
      'phone': phone,
      'is_default': is_default,
    };
  }

  Address toEntity() {
    return Address(
      id: id,
      userId: user_id,
      fullAddress: full_address,
      city: city,
      state: state,
      zipCode: zip_code,
      phone: phone,
      isDefault: is_default,
      createdAt: created_at,
      updatedAt: updated_at,
    );
  }
}

class InboxMessageDTO {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String category;
  final bool isRead;
  final DateTime createdAt;

  InboxMessageDTO({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    required this.createdAt,
  });

  factory InboxMessageDTO.fromJson(Map<String, dynamic> json) {
    return InboxMessageDTO(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String? ?? 'General',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'category': category,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  InboxMessage toEntity() {
    return InboxMessage(
      id: id,
      userId: userId,
      title: title,
      body: body,
      category: category,
      isRead: isRead,
      createdAt: createdAt,
    );
  }
}
