/// Remote Data Source - Handles all Supabase API calls
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dtos.dart';

class RemoteDataSource {
  final SupabaseClient supabaseClient;

  RemoteDataSource({required this.supabaseClient});

  // ==================== PRODUCTS ====================

  /// Fetch paginated products
  ///
  /// Parameters:
  ///   - page: Page number (1-based)
  ///   - limit: Items per page (default: 20)
  ///   - categoryId: Optional category filter
  ///
  /// Returns: List of ProductDTO
  Future<List<ProductDTO>> getProducts({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async {
    try {
      final offset = (page - 1) * limit;
      print(
        'RemoteDataSource: Querying products - '
        'Page: $page, Offset: $offset, Limit: $limit',
      );

      final response = await _fetchProductsResponse(
        offset: offset,
        limit: limit,
        categoryId: categoryId,
        activeOnly: true,
      );

      print('RemoteDataSource: Raw response type: ${response.runtimeType}');
      print('RemoteDataSource: Raw response: $response');

      final responseList = List<dynamic>.from(response as List);
      print('RemoteDataSource: Response list length: ${responseList.length}');

      if (responseList.isEmpty) {
        print(
          'RemoteDataSource: No products found with is_active=true. '
          'Checking database without that filter...',
        );
        final allResponse = await _fetchProductsResponse(
          offset: offset,
          limit: limit,
          categoryId: categoryId,
          activeOnly: false,
        );
        final allProducts = List<dynamic>.from(allResponse as List);
        print(
          'RemoteDataSource: All products (no filter): '
          '${allProducts.length} items',
        );
        if (allProducts.isNotEmpty) {
          print('RemoteDataSource: First fallback product: ${allProducts[0]}');
          responseList.addAll(allProducts);
        }
      }

      final dtos = <ProductDTO>[];
      for (int i = 0; i < responseList.length; i++) {
        try {
          final json = responseList[i] as Map<String, dynamic>;
          print('RemoteDataSource: Parsing product $i: ${json.toString()}');
          final dto = ProductDTO.fromJson(json);
          dtos.add(dto);
          print('RemoteDataSource: Successfully parsed product: ${dto.title}');
        } catch (parseError) {
          print(
            'RemoteDataSource: Error parsing product at index $i: '
            '$parseError',
          );
          print('RemoteDataSource: Raw JSON: ${responseList[i]}');
        }
      }

      print('RemoteDataSource: Successfully converted ${dtos.length} DTOs');
      return dtos;
    } catch (e) {
      print('RemoteDataSource Error: $e');
      print('RemoteDataSource stack trace: ${StackTrace.current}');
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Fetch single product by ID
  Future<ProductDTO> getProductById(int id) async {
    try {
      final response =
          await supabaseClient.from('products').select().eq('id', id).single();

      return ProductDTO.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Search products by title or description
  Future<List<ProductDTO>> searchProducts(String query) async {
    try {
      List<dynamic> response = List<dynamic>.from(
        await supabaseClient
            .from('products')
            .select()
            .eq('is_active', true)
            .or('title.ilike.%$query%,description.ilike.%$query%')
            .order('created_at', ascending: false) as List,
      );

      if (response.isEmpty) {
        response = List<dynamic>.from(
          await supabaseClient
              .from('products')
              .select()
              .or('title.ilike.%$query%,description.ilike.%$query%')
              .order('created_at', ascending: false) as List,
        );
      }

      return response
          .map((json) => ProductDTO.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Fetch product with images
  Future<ProductDTO> getProductWithImages(int productId) async {
    try {
      final response = await supabaseClient
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      return ProductDTO.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch product with images: $e');
    }
  }

  // ==================== CATEGORIES ====================

  /// Fetch all active categories
  Future<List<CategoryDTO>> getCategories() async {
    try {
      final response = await supabaseClient
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => CategoryDTO.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Fetch category by ID
  Future<CategoryDTO> getCategoryById(int id) async {
    try {
      final response = await supabaseClient
          .from('categories')
          .select()
          .eq('id', id)
          .single();

      return CategoryDTO.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  // ==================== ORDERS ====================

  /// Create new order
  ///
  /// Returns: Order ID
  Future<int> createOrder({
    required String userId,
    required int totalPrice,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final orderResponse = await supabaseClient
          .from('orders')
          .insert({
            'user_id': userId,
            'total_price': totalPrice,
            'status': 'pending',
          })
          .select('id')
          .single();

      final orderId = orderResponse['id'] as int;

      final itemsWithOrderId = items.map((item) {
        return {...item, 'order_id': orderId};
      }).toList();

      await supabaseClient.from('order_items').insert(itemsWithOrderId);

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Fetch user's orders
  Future<List<OrderDTO>> getUserOrders(String userId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => OrderDTO.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Fetch order details with items
  Future<OrderDTO> getOrderWithItems(int orderId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      return OrderDTO.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }

  /// Update order status (admin only)
  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      await supabaseClient.from('orders').update({'status': status}).eq(
        'id',
        orderId,
      );
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // ==================== REVIEWS ====================

  /// Fetch reviews for product
  Future<List<ReviewDTO>> getProductReviews(int productId) async {
    try {
      final response = await supabaseClient
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewDTO.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  /// Create review
  Future<void> createReview({
    required int productId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      await supabaseClient.from('reviews').insert({
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // ==================== ADDRESSES ====================

  /// Fetch user's addresses
  Future<List<AddressDTO>> getUserAddresses(String userId) async {
    try {
      final response = await supabaseClient
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      return (response as List)
          .map((json) => AddressDTO.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  /// Create address
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
      final response = await supabaseClient
          .from('addresses')
          .insert({
            'user_id': userId,
            'full_address': fullAddress,
            'city': city,
            'state': state,
            'zip_code': zipCode,
            'phone': phone,
            'is_default': isDefault,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create address: $e');
    }
  }

  /// Update address
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
      await supabaseClient.from('addresses').update({
        'full_address': fullAddress,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'phone': phone,
        'is_default': isDefault,
      }).eq('id', addressId);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  /// Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      await supabaseClient.from('addresses').delete().eq('id', addressId);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // ==================== USER PROFILE ====================

  /// Fetch user profile
  Future<UserProfileDTO> getUserProfile(String userId) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfileDTO.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;

      await supabaseClient.from('profiles').update(updateData).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String name,
    String? phone,
  }) async {
    try {
      await supabaseClient.from('profiles').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'customer',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to upsert user profile: $e');
    }
  }

  // ==================== PAYMENTS ====================

  Future<Map<String, dynamic>> initiateMpesaStkPush({
    required int orderId,
    required String phoneNumber,
    required int amount,
  }) async {
    try {
      if (supabaseClient.auth.currentUser == null) {
        throw Exception(
          'Please sign in before requesting an M-Pesa STK push',
        );
      }

      final response = await supabaseClient.functions.invoke(
        'mpesa-stk-push',
        body: {
          'phone': phoneNumber,
          'amount': amount,
          'orderId': orderId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw Exception(
            data['error']?.toString() ?? 'Failed to initiate M-Pesa payment',
          );
        }
        return data;
      }

      if (data is Map) {
        final responseMap = Map<String, dynamic>.from(data);
        if (responseMap['success'] == false) {
          throw Exception(
            responseMap['error']?.toString() ??
                'Failed to initiate M-Pesa payment',
          );
        }
        return responseMap;
      }

      throw Exception('Unexpected M-Pesa response from server');
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw Exception(
          'M-Pesa backend is not deployed yet. Deploy the Supabase edge '
          'function "mpesa-stk-push" for project xjmgfmkhtzdybbgkintb, then '
          'try again.',
        );
      }
      throw Exception(
        'Failed to initiate M-Pesa payment: '
        '${e.details ?? e.reasonPhrase ?? e.toString()}',
      );
    } catch (e) {
      throw Exception('Failed to initiate M-Pesa payment: $e');
    }
  }

  Future<Map<String, dynamic>> getMpesaPaymentStatus({
    required int orderId,
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'payment-status',
        method: HttpMethod.get,
        queryParameters: {
          'order_id': orderId.toString(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw Exception(
            data['error']?.toString() ?? 'Failed to fetch payment status',
          );
        }
        return data;
      }

      if (data is Map) {
        final responseMap = Map<String, dynamic>.from(data);
        if (responseMap['success'] == false) {
          throw Exception(
            responseMap['error']?.toString() ??
                'Failed to fetch payment status',
          );
        }
        return responseMap;
      }

      throw Exception('Unexpected payment status response from server');
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw Exception(
          'Payment status backend is not deployed yet. Deploy the Supabase '
          'edge function "payment-status" for project xjmgfmkhtzdybbgkintb.',
        );
      }
      throw Exception(
          'Failed to fetch payment status: ${e.details ?? e.reasonPhrase ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to fetch payment status: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> watchPaymentsForOrder(int orderId) {
    return supabaseClient
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .map(
          (rows) => rows
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false),
        );
  }

  Future<Map<String, dynamic>?> getLatestPaymentForOrder(int orderId) async {
    try {
      final response = await supabaseClient
          .from('payments')
          .select(
            'id, order_id, status, mpesa_receipt_number, phone_number, amount, '
            'customer_message, result_desc, checkout_request_id, updated_at',
          )
          .eq('order_id', orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch latest payment: $e');
    }
  }

  // ==================== STOCK MANAGEMENT ====================

  /// Reduce product stock (after purchase)
  Future<void> reduceProductStock(int productId, int quantity) async {
    try {
      await supabaseClient.rpc(
        'reduce_stock',
        params: {
          'product_id': productId,
          'qty': quantity,
        },
      );
    } catch (e) {
      throw Exception('Failed to reduce stock: $e');
    }
  }

  // ==================== IMAGE URLS ====================

  /// Get product images
  Future<List<String>> getProductImages(int productId) async {
    try {
      final response = await supabaseClient
          .from('product_images')
          .select('image_url')
          .eq('product_id', productId)
          .order('order', ascending: true);

      return (response as List)
          .map((json) => json['image_url'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch product images: $e');
    }
  }

  Future<dynamic> _fetchProductsResponse({
    required int offset,
    required int limit,
    required int? categoryId,
    required bool activeOnly,
  }) async {
    dynamic query = supabaseClient.from('products').select();

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    if (categoryId != null) {
      print('RemoteDataSource: Filtering by category_id: $categoryId');
      query = query.eq('category_id', categoryId);
    }

    return query.order('created_at', ascending: false).range(
          offset,
          offset + limit - 1,
        );
  }
}
