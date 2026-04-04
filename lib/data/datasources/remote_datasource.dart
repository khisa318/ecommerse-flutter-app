/// Remote Data Source - Handles all Supabase API calls
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/exceptions.dart';
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
    List<int>? categoryIds,
  }) async {
    return _runSupabaseRequest(
      operation: 'fetch_products',
      fallbackMessage: 'Unable to load products right now.',
      request: () async {
        final offset = (page - 1) * limit;
        print(
          'RemoteDataSource: Querying products - '
          'Page: $page, Offset: $offset, Limit: $limit',
        );

        final response = await _fetchProductsResponse(
          offset: offset,
          limit: limit,
          categoryIds: categoryIds,
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
            categoryIds: categoryIds,
            activeOnly: false,
          );
          final allProducts = List<dynamic>.from(allResponse as List);
          print(
            'RemoteDataSource: All products (no filter): '
            '${allProducts.length} items',
          );
          if (allProducts.isNotEmpty) {
            print(
                'RemoteDataSource: First fallback product: ${allProducts[0]}');
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
            print(
                'RemoteDataSource: Successfully parsed product: ${dto.title}');
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
      },
    );
  }

  /// Fetch single product by ID
  Future<ProductDTO> getProductById(int id) async {
    return _runSupabaseRequest(
      operation: 'fetch_product_by_id',
      fallbackMessage: 'Unable to load this product right now.',
      request: () async {
        final response = await supabaseClient
            .from('products')
            .select()
            .eq('id', id)
            .single();

        return ProductDTO.fromJson(response);
      },
    );
  }

  /// Search products by title or description
  Future<List<ProductDTO>> searchProducts(String query) async {
    return _runSupabaseRequest(
      operation: 'search_products',
      fallbackMessage: 'Unable to search products right now.',
      request: () async {
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
      },
    );
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
    return _runSupabaseRequest(
      operation: 'fetch_categories',
      fallbackMessage: 'Unable to load categories right now.',
      request: () async {
        final response = await supabaseClient
            .from('categories')
            .select()
            .order('name', ascending: true);

        return (response as List)
            .map((json) => CategoryDTO.fromJson(json))
            .toList();
      },
    );
  }

  /// Fetch category by ID
  Future<CategoryDTO> getCategoryById(int id) async {
    return _runSupabaseRequest(
      operation: 'fetch_category_by_id',
      fallbackMessage: 'Unable to load this category right now.',
      request: () async {
        final response = await supabaseClient
            .from('categories')
            .select()
            .eq('id', id)
            .single();

        return CategoryDTO.fromJson(response);
      },
    );
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
    return _runSupabaseRequest(
      operation: 'fetch_user_orders',
      fallbackMessage: 'Unable to load your orders right now.',
      request: () async {
        final response = await supabaseClient
            .from('orders')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => OrderDTO.fromJson(json))
            .toList();
      },
    );
  }

  /// Fetch order details with items
  Future<OrderDTO> getOrderWithItems(int orderId) async {
    return _runSupabaseRequest(
      operation: 'fetch_order_with_items',
      fallbackMessage: 'Unable to load this order right now.',
      request: () async {
        final response = await supabaseClient
            .from('orders')
            .select('*, order_items(*)')
            .eq('id', orderId)
            .single();

        return OrderDTO.fromJson(response);
      },
    );
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
    return _runSupabaseRequest(
      operation: 'fetch_user_profile',
      fallbackMessage: 'Unable to load your profile right now.',
      request: () async {
        final response = await supabaseClient
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        return UserProfileDTO.fromJson(response);
      },
    );
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      };

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
    String? address,
  }) async {
    try {
      await supabaseClient.from('profiles').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'phone': phone,
        'address': address,
        'role': 'customer',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to upsert user profile: $e');
    }
  }

  Future<void> deleteCurrentUserAccount() async {
    try {
      await supabaseClient.functions
          .invoke('delete-account', method: HttpMethod.post);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // ==================== PAYMENTS ====================

  Future<Map<String, dynamic>> initiateMpesaStkPush({
    required int orderId,
    required String phoneNumber,
    required int amount,
  }) async {
    return _runSupabaseRequest(
      operation: 'initiate_mpesa_stk_push',
      fallbackMessage: 'Unable to start M-Pesa right now. Please try again.',
      request: () async {
        if (supabaseClient.auth.currentUser == null) {
          throw BusinessException(
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
      },
      onError: (error) {
        if (error is FunctionException && error.status == 404) {
          throw Exception(
            'M-Pesa backend is not deployed yet. Deploy the Supabase edge '
            'function "mpesa-stk-push" for project xjmgfmkhtzdybbgkintb, then '
            'try again.',
          );
        }
        return UiSafeErrorMapper.toAppException(
          error,
          fallbackMessage:
              'Unable to start M-Pesa right now. Please try again.',
        );
      },
    );
  }

  Future<Map<String, dynamic>> getMpesaPaymentStatus({
    required int orderId,
  }) async {
    return _runSupabaseRequest(
      operation: 'fetch_mpesa_payment_status',
      fallbackMessage: 'Unable to check payment status right now.',
      request: () async {
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
      },
      onError: (error) {
        if (error is FunctionException && error.status == 404) {
          throw Exception(
            'Payment status backend is not deployed yet. Deploy the Supabase '
            'edge function "payment-status" for project xjmgfmkhtzdybbgkintb.',
          );
        }
        return UiSafeErrorMapper.toAppException(
          error,
          fallbackMessage: 'Unable to check payment status right now.',
        );
      },
    );
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
    return _runSupabaseRequest(
      operation: 'fetch_latest_payment',
      fallbackMessage: 'Unable to load payment details right now.',
      request: () async {
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
      },
    );
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
    return _runSupabaseRequest(
      operation: 'fetch_product_images',
      fallbackMessage: 'Unable to load product images right now.',
      request: () async {
        final response = await supabaseClient
            .from('product_images')
            .select('image_url')
            .eq('product_id', productId)
            .order('order', ascending: true);

        return (response as List)
            .map((json) => json['image_url'] as String)
            .toList();
      },
    );
  }

  Future<dynamic> _fetchProductsResponse({
    required int offset,
    required int limit,
    required List<int>? categoryIds,
    required bool activeOnly,
  }) async {
    dynamic query = supabaseClient.from('products').select();

    if (categoryIds != null && categoryIds.isNotEmpty) {
      print('RemoteDataSource: Filtering by category_ids: $categoryIds');
      query = query.inFilter('category_id', categoryIds);
    }

    return query.order('created_at', ascending: false).range(
          offset,
          offset + limit - 1,
        );
  }

  Future<T> _runSupabaseRequest<T>({
    required String operation,
    required Future<T> Function() request,
    String? fallbackMessage,
    AppException Function(Object error)? onError,
  }) async {
    var attempt = 0;

    while (true) {
      try {
        return await request();
      } catch (error, stackTrace) {
        UiSafeErrorMapper.logTechnicalError(operation, error, stackTrace);

        if (UiSafeErrorMapper.isNetworkError(error) && attempt < 1) {
          attempt += 1;
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }

        if (onError != null) {
          throw onError(error);
        }

        throw UiSafeErrorMapper.toAppException(
          error,
          fallbackMessage: fallbackMessage,
        );
      }
    }
  }
}
