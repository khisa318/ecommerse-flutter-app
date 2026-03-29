import 'package:flutter/material.dart';
import 'review.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> galleryImages;
  final double rating;
  final int reviewCount;
  final List<Review> reviews;
  final List<ProductVariant> variants;
  final List<String> features;
  final String category;
  final int stock;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.galleryImages,
    required this.rating,
    required this.reviewCount,
    this.reviews = const [],
    required this.variants,
    required this.features,
    required this.category,
    required this.stock,
    this.isActive = true,
  });

  bool get isOnSale => originalPrice != null && originalPrice! > price;

  double get discountPercentage {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  /// Get all available attribute names from variants (e.g., ['color', 'storage'])
  List<String> get availableAttributes {
    final attributes = <String>{};
    for (var variant in variants) {
      attributes.addAll(variant.attributes.keys);
    }
    return attributes.toList();
  }

  /// Get all unique values for a specific attribute
  List<String> getAttributeValues(String attributeName) {
    final values = <String>{};
    for (var variant in variants) {
      if (variant.attributes.containsKey(attributeName)) {
        values.add(variant.attributes[attributeName]!);
      }
    }
    return values.toList();
  }

  /// Find matching variant based on selected attributes
  ProductVariant? findVariant(Map<String, String> selectedAttributes) {
    for (var variant in variants) {
      bool match = true;
      selectedAttributes.forEach((key, value) {
        if (variant.attributes[key] != value) {
          match = false;
        }
      });
      if (match) return variant;
    }
    return null;
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? description,
    double? price,
    double? originalPrice,
    String? imageUrl,
    List<String>? galleryImages,
    double? rating,
    int? reviewCount,
    List<Review>? reviews,
    List<ProductVariant>? variants,
    List<String>? features,
    String? category,
    int? stock,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      reviews: reviews ?? this.reviews,
      variants: variants ?? this.variants,
      features: features ?? this.features,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      brand: json['brand'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'],
      galleryImages: List<String>.from(json['galleryImages'] ?? []),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => Review.fromJson(e))
              .toList() ??
          [],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e))
              .toList() ??
          [],
      features: List<String>.from(json['features'] ?? []),
      category: json['category'],
      stock: json['stock'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'rating': rating,
      'reviewCount': reviewCount,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'variants': variants.map((v) => v.toJson()).toList(),
      'features': features,
      'category': category,
      'stock': stock,
      'isActive': isActive,
    };
  }
}

class ProductVariant {
  final String id;
  final double? price; // Optional override
  final int stock;
  final String? imageUrl; // Optional override
  final Map<String, String> attributes;

  ProductVariant({
    required this.id,
    this.price,
    required this.stock,
    this.imageUrl,
    required this.attributes,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'].toString(),
      price: (json['price'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'],
      attributes: Map<String, String>.from(json['attributes'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'attributes': attributes,
    };
  }
}

class Category {
  final String id;
  final String name;
  final String icon;
  final Color backgroundColor;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColor,
  });
}

class ProductColor {
  final String name;
  final String hexCode;

  ProductColor({
    required this.name,
    required this.hexCode,
  });
}
