/// Model Adapter - Converts domain entities to legacy models for UI compatibility
import '../domain/entities/entities.dart' as entities;
import '../models/product.dart' as models;

extension ProductEntityToModel on entities.Product {
  /// Convert domain entity Product to legacy Product model
  models.Product toModel() {
    final hasDiscount = discountPercentage > 0;
    final currentPrice = price / 100.0;
    final originalPrice =
        hasDiscount ? currentPrice / (1 - (discountPercentage / 100)) : null;

    return models.Product(
      id: id.toString(),
      name: title,
      brand: 'Generic Brand', // Not available in entity
      description: description,
      price: currentPrice,
      originalPrice: originalPrice,
      imageUrl: imageUrl,
      galleryImages: [imageUrl],
      rating: 4.5, // Not available in entity
      reviewCount: 0, // Not available in entity
      reviews: [],
      colors: const ['Black', 'White'],
      storageOptions: const ['128GB', '256GB'],
      features: [description],
      category: 'Electronics',
      isOnSale: hasDiscount,
    );
  }
}
