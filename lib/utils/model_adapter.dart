/// Model Adapter - Converts domain entities to legacy models for UI compatibility
import '../domain/entities/entities.dart' as entities;
import '../models/product.dart' as models;

extension ProductEntityToModel on entities.Product {
  /// Convert domain entity Product to legacy Product model
  models.Product toModel({String? categoryName}) {
    final hasDiscount = discountPercentage > 0;
    final currentPrice = price / 100.0;
    final originalPrice =
        hasDiscount ? currentPrice / (1 - (discountPercentage / 100)) : null;

    return models.Product(
      id: id.toString(),
      name: title,
      brand: 'Generic Brand', 
      description: description,
      price: currentPrice,
      originalPrice: originalPrice,
      imageUrl: imageUrl,
      galleryImages: images,
      rating: 4.5, 
      reviewCount: 0, 
      reviews: [],
      variants: variants
          .map((v) => models.ProductVariant(
                id: v.id,
                price: v.price / 100.0,
                stock: v.stock,
                imageUrl: v.imageUrl,
                attributes: v.attributes,
              ))
          .toList(),
      features: [description],
      category: categoryName ?? 'Electronics',
      stock: stock,
      isActive: isActive,
    );
  }
}
