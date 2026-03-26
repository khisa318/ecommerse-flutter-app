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
  final List<String> colors;
  final List<String> storageOptions;
  final List<String> features;
  final String category;
  final bool isOnSale;

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
    required this.colors,
    required this.storageOptions,
    required this.features,
    required this.category,
    this.isOnSale = false,
  });

  double get discountPercentage {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
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
    List<String>? colors,
    List<String>? storageOptions,
    List<String>? features,
    String? category,
    bool? isOnSale,
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
      colors: colors ?? this.colors,
      storageOptions: storageOptions ?? this.storageOptions,
      features: features ?? this.features,
      category: category ?? this.category,
      isOnSale: isOnSale ?? this.isOnSale,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null ? (json['originalPrice'] as num).toDouble() : null,
      imageUrl: json['imageUrl'],
      galleryImages: List<String>.from(json['galleryImages'] ?? []),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'],
      reviews: (json['reviews'] as List<dynamic>?)?.map((e) => Review.fromJson(e)).toList() ?? [],
      colors: List<String>.from(json['colors'] ?? []),
      storageOptions: List<String>.from(json['storageOptions'] ?? []),
      features: List<String>.from(json['features'] ?? []),
      category: json['category'],
      isOnSale: json['isOnSale'] ?? false,
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
      'colors': colors,
      'storageOptions': storageOptions,
      'features': features,
      'category': category,
      'isOnSale': isOnSale,
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
