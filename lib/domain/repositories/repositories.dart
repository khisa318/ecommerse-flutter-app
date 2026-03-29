/// Abstract Repository Interfaces - Define contracts for data operations
import '../../domain/entities/entities.dart';

abstract class ProductRepository {
  /// Fetch paginated products from backend
  /// 
  /// Parameters:
  ///   - page: Page number (1-based)
  ///   - limit: Items per page
  ///   - categoryId: Optional category filter
  /// 
  /// Returns: List of Product entities
  Future<List<Product>> getProducts({
    int page,
    int limit,
    List<int>? categoryIds,
  });

  /// Fetch single product by ID
  Future<Product> getProductById(int id);

  /// Search products
  Future<List<Product>> searchProducts(String query);

  /// Fetch product with reviews
  Future<(Product, List<Review>)> getProductWithReviews(int productId);
}

abstract class CategoryRepository {
  /// Fetch all categories
  Future<List<Category>> getCategories();

  /// Fetch category by ID
  Future<Category> getCategoryById(int id);
}

abstract class OrderRepository {
  /// Create new order
  /// 
  /// Parameters:
  ///   - userId: User ID
  ///   - totalPrice: Total price in cents
  ///   - items: List of {product_id, quantity, price_at_purchase}
  /// 
  /// Returns: Order ID
  Future<int> createOrder({
    required String userId,
    required int totalPrice,
    required List<Map<String, dynamic>> items,
  });

  /// Fetch user's orders
  Future<List<Order>> getUserOrders(String userId);

  /// Fetch order details
  Future<Order> getOrderWithItems(int orderId);

  /// Update order status
  Future<void> updateOrderStatus(int orderId, String status);

  /// Reduce product stock after purchase
  Future<void> reduceProductStock(int productId, int quantity);
}

abstract class ReviewRepository {
  /// Fetch reviews for product
  Future<List<Review>> getProductReviews(int productId);

  /// Create review
  Future<void> createReview({
    required int productId,
    required String userId,
    required int rating,
    String? comment,
  });
}

abstract class AddressRepository {
  /// Fetch user's addresses
  Future<List<Address>> getUserAddresses(String userId);

  /// Create address
  Future<String> createAddress({
    required String userId,
    required String fullAddress,
    required String city,
    required String state,
    required String zipCode,
    required String phone,
    bool isDefault,
  });

  /// Update address
  Future<void> updateAddress({
    required String addressId,
    required String fullAddress,
    required String city,
    required String state,
    required String zipCode,
    required String phone,
    bool isDefault,
  });

  /// Delete address
  Future<void> deleteAddress(String addressId);
}

abstract class UserProfileRepository {
  /// Fetch user profile
  Future<UserProfile> getUserProfile(String userId);

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? address,
  });
}
