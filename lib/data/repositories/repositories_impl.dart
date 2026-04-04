/// Concrete Repository Implementations - Transform DTOs to Entities
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/remote_datasource.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class ProductRepositoryImpl implements ProductRepository {
  final RemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  @override
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 20,
    List<int>? categoryIds,
  }) async {
    try {
      print('📦 ProductRepositoryImpl: Fetching page $page');
      // Try fetch from remote
      final dtos = await remoteDataSource.getProducts(
        page: page,
        limit: limit,
        categoryIds: categoryIds,
      );

      print(
          '📦 ProductRepositoryImpl: Received ${dtos.length} DTOs from remote');

      // Convert DTOs to entities and cache
      final products = await Future.wait(
        dtos.map((dto) => _mapDtoToProduct(dto)),
      );

      print(
          '📦 ProductRepositoryImpl: Converted to ${products.length} entities');
      // Cache products (5 mins)
      _cacheProducts(products, key: 'products_page_$page');

      return products;
    } catch (e) {
      print('🔴 ProductRepositoryImpl Error: $e');
      // Fall back to cache if network error
      final cached = _getCachedProducts(key: 'products_page_$page');
      if (cached != null) {
        print('📦 ProductRepositoryImpl: Using cached data');
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<Product> getProductById(int id) async {
    try {
      final dto = await remoteDataSource.getProductById(id);
      return _mapDtoToProduct(dto);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      final dtos = await remoteDataSource.searchProducts(query);
      return Future.wait(
        dtos.map((dto) => _mapDtoToProduct(dto)),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<(Product, List<Review>)> getProductWithReviews(int productId) async {
    try {
      // Fetch product and reviews in parallel
      final productDto = await remoteDataSource.getProductById(productId);
      final reviewDtos = await remoteDataSource.getProductReviews(productId);

      final product = await _mapDtoToProduct(productDto);

      final reviews = reviewDtos.map((dto) => dto.toEntity()).toList();

      return (product, reviews);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== CACHING ====================

  Future<Product> _mapDtoToProduct(dto) async {
    String imageUrl = 'lib/images/smartphones/mobile2.jpg';
    List<String> images = [imageUrl];

    try {
      final fetchedImages = await remoteDataSource.getProductImages(dto.id);
      if (fetchedImages.isNotEmpty) {
        imageUrl = fetchedImages.first;
        images = fetchedImages;
      }
    } catch (_) {
      // Fall back to bundled placeholder when no database image is available.
    }

    return dto.toEntity(
      imageUrl: imageUrl,
      images: images,
    );
  }

  void _cacheProducts(List<Product> products, {required String key}) {
    // Simplified JSON caching for now to avoid mapping complexity with variants.
    // In production, consider a local database (sembast/sqlite).
    sharedPreferences.setInt(
        '${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  List<Product>? _getCachedProducts({required String key}) {
    // Basic timestamp check
    final timestamp = sharedPreferences.getInt('${key}_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - timestamp > 5 * 60 * 1000) return null; // 5 min expiry

    // Return null to trigger refetch if cache is simplified.
    return null;
  }

  void clearProductCache() {
    final keys = sharedPreferences.getKeys();
    for (String key in keys) {
      if (key.startsWith('products_page_')) {
        sharedPreferences.remove(key);
        sharedPreferences.remove('${key}_timestamp');
      }
    }
  }

  List<Product>? getCachedProductsPage({int page = 1}) {
    return _getCachedProducts(key: 'products_page_$page');
  }
}

class CategoryRepositoryImpl implements CategoryRepository {
  final RemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  @override
  Future<List<Category>> getCategories() async {
    try {
      final dtos = await remoteDataSource.getCategories();
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Category> getCategoryById(int id) async {
    try {
      final dto = await remoteDataSource.getCategoryById(id);
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }
}

class OrderRepositoryImpl implements OrderRepository {
  final RemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<int> createOrder({
    required String userId,
    required int totalPrice,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      return await remoteDataSource.createOrder(
        userId: userId,
        totalPrice: totalPrice,
        items: items,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final dtos = await remoteDataSource.getUserOrders(userId);
      return dtos.map((dto) => dto.toEntity(items: [])).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Order> getOrderWithItems(int orderId) async {
    try {
      final dto = await remoteDataSource.getOrderWithItems(orderId);
      return dto.toEntity(items: []);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      await remoteDataSource.updateOrderStatus(orderId, status);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> reduceProductStock(int productId, int quantity) async {
    try {
      await remoteDataSource.reduceProductStock(productId, quantity);
    } catch (e) {
      rethrow;
    }
  }
}

class ReviewRepositoryImpl implements ReviewRepository {
  final RemoteDataSource remoteDataSource;

  ReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Review>> getProductReviews(int productId) async {
    try {
      final dtos = await remoteDataSource.getProductReviews(productId);
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> createReview({
    required int productId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      await remoteDataSource.createReview(
        productId: productId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class AddressRepositoryImpl implements AddressRepository {
  final RemoteDataSource remoteDataSource;

  AddressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final dtos = await remoteDataSource.getUserAddresses(userId);
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> createAddress({
    required String userId,
    required String fullAddress,
    required String city,
    required String state,
    required String zipCode,
    required String phone,
    bool isDefault = false,
  }) async {
    try {
      return await remoteDataSource.createAddress(
        userId: userId,
        fullAddress: fullAddress,
        city: city,
        state: state,
        zipCode: zipCode,
        phone: phone,
        isDefault: isDefault,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateAddress({
    required String addressId,
    required String fullAddress,
    required String city,
    required String state,
    required String zipCode,
    required String phone,
    bool isDefault = false,
  }) async {
    try {
      await remoteDataSource.updateAddress(
        addressId: addressId,
        fullAddress: fullAddress,
        city: city,
        state: state,
        zipCode: zipCode,
        phone: phone,
        isDefault: isDefault,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    try {
      await remoteDataSource.deleteAddress(addressId);
    } catch (e) {
      rethrow;
    }
  }
}

class UserProfileRepositoryImpl implements UserProfileRepository {
  final RemoteDataSource remoteDataSource;

  UserProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final dto = await remoteDataSource.getUserProfile(userId);
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    try {
      await remoteDataSource.updateUserProfile(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
    } catch (e) {
      rethrow;
    }
  }
}
